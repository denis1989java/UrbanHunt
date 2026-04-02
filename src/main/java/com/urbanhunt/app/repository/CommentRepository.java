package com.urbanhunt.app.repository;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.urbanhunt.app.model.Comment;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class CommentRepository {

    private final Firestore firestore;

    private static final String COLLECTION_NAME = "comments";
    private static final int DEFAULT_PAGE_SIZE = 20;

    public Comment save(Comment comment) {
        try {
            String id = comment.getId();
            if (id == null) {
                id = firestore.collection(COLLECTION_NAME).document().getId();
                comment.setId(id);
            }
            firestore.collection(COLLECTION_NAME).document(id).set(comment).get();
            return comment;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to save comment", e);
        }
    }

    public Comment findById(String id) {
        try {
            var doc = firestore.collection(COLLECTION_NAME).document(id).get().get();
            return doc.exists() ? doc.toObject(Comment.class) : null;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find comment", e);
        }
    }

    public List<Comment> findByChallengeId(String challengeId, int limit, String startAfter) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("challengeId", challengeId)
                    .orderBy("createdAt", Query.Direction.DESCENDING)
                    .limit(limit > 0 ? limit : DEFAULT_PAGE_SIZE);

            if (startAfter != null && !startAfter.isEmpty()) {
                var lastDoc = firestore.collection(COLLECTION_NAME).document(startAfter).get().get();
                if (lastDoc.exists()) {
                    query = query.startAfter(lastDoc);
                }
            }

            var docs = query.get().get().getDocuments();
            return docs.stream()
                    .map(doc -> doc.toObject(Comment.class))
                    .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find comments", e);
        }
    }

    public Long countByChallengeId(String challengeId) {
        try {
            var docs = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("challengeId", challengeId)
                    .count()
                    .get()
                    .get();
            return docs.getCount();
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to count comments", e);
        }
    }

    public void deleteById(String id) {
        try {
            firestore.collection(COLLECTION_NAME).document(id).delete().get();
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to delete comment", e);
        }
    }

}