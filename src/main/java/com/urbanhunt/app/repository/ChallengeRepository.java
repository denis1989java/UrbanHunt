package com.urbanhunt.app.repository;

import com.google.cloud.firestore.Firestore;
import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Challenge.ChallengeStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class ChallengeRepository {

    private final Firestore firestore;
    private static final String COLLECTION_NAME = "challenges";

    public Challenge save(Challenge challenge) {
        try {
            String id = challenge.getId();
            if (id == null) {
                id = firestore.collection(COLLECTION_NAME).document().getId();
                challenge.setId(id);
            }
            firestore.collection(COLLECTION_NAME).document(id).set(challenge).get();
            return challenge;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to save challenge", e);
        }
    }

    public Challenge findById(String id) {
        try {
            var doc = firestore.collection(COLLECTION_NAME).document(id).get().get();
            return doc.exists() ? doc.toObject(Challenge.class) : null;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenge", e);
        }
    }

    public List<Challenge> findAll() {
        try {
            var docs = firestore.collection(COLLECTION_NAME).get().get().getDocuments();
            return docs.stream()
                    .map(doc -> doc.toObject(Challenge.class))
                    .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find all challenges", e);
        }
    }

    public List<Challenge> findByStatus(ChallengeStatus status) {
        try {
            var docs = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("status", status.name())
                    .get()
                    .get()
                    .getDocuments();
            return docs.stream()
                    .map(doc -> doc.toObject(Challenge.class))
                    .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by status", e);
        }
    }

    public List<Challenge> findByCityName(String cityName) {
        try {
            var docs = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("cityName", cityName)
                    .get()
                    .get()
                    .getDocuments();
            return docs.stream()
                    .map(doc -> doc.toObject(Challenge.class))
                    .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by city", e);
        }
    }

    public List<Challenge> findByCityNameAndStatus(String cityName, ChallengeStatus status) {
        try {
            var docs = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("cityName", cityName)
                    .whereEqualTo("status", status.name())
                    .get()
                    .get()
                    .getDocuments();
            return docs.stream()
                    .map(doc -> doc.toObject(Challenge.class))
                    .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by city and status", e);
        }
    }

    public void deleteById(String id) {
        try {
            firestore.collection(COLLECTION_NAME).document(id).delete().get();
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to delete challenge", e);
        }
    }

}