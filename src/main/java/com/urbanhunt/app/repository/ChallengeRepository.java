package com.urbanhunt.app.repository;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Challenge.ChallengeStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;
import java.util.Date;
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

    public List<Challenge> findAll(int limit, Date lastCreatedAt) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                .orderBy("createdAt", Query.Direction.DESCENDING);

            if (lastCreatedAt != null) {
                query = query.startAfter(lastCreatedAt);
            }

            var docs = query.limit(limit).get().get().getDocuments();
            return docs.stream()
                .map(doc -> doc.toObject(Challenge.class))
                .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find all challenges", e);
        }
    }

    public List<Challenge> findByStatus(ChallengeStatus status, int limit, Date lastCreatedAt) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                .whereEqualTo("status", status.name())
                .orderBy("createdAt", Query.Direction.DESCENDING);

            if (lastCreatedAt != null) {
                query = query.startAfter(lastCreatedAt);
            }

            var docs = query.limit(limit).get().get().getDocuments();
            return docs.stream()
                .map(doc -> doc.toObject(Challenge.class))
                .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by status", e);
        }
    }

    public List<Challenge> findByCityName(String cityName, int limit, Date lastCreatedAt) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                .whereEqualTo("cityName", cityName)
                .orderBy("createdAt", Query.Direction.DESCENDING);

            if (lastCreatedAt != null) {
                query = query.startAfter(lastCreatedAt);
            }

            var docs = query.limit(limit).get().get().getDocuments();
            return docs.stream()
                .map(doc -> doc.toObject(Challenge.class))
                .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by city", e);
        }
    }

    public List<Challenge> findByCityNameAndStatus(String cityName, ChallengeStatus status, int limit, Date lastCreatedAt) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                .whereEqualTo("cityName", cityName)
                .whereEqualTo("status", status.name())
                .orderBy("createdAt", Query.Direction.DESCENDING);

            if (lastCreatedAt != null) {
                query = query.startAfter(lastCreatedAt);
            }

            var docs = query.limit(limit).get().get().getDocuments();
            return docs.stream()
                .map(doc -> doc.toObject(Challenge.class))
                .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by city and status", e);
        }
    }

    public List<Challenge> findActiveAndCompleted(int limit, Date lastCreatedAt) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                .whereIn("status", java.util.Arrays.asList(ChallengeStatus.ACTIVE.name(), ChallengeStatus.COMPLETED.name()))
                .orderBy("createdAt", Query.Direction.DESCENDING);

            if (lastCreatedAt != null) {
                query = query.startAfter(lastCreatedAt);
            }

            var docs = query.limit(limit).get().get().getDocuments();
            return docs.stream()
                .map(doc -> doc.toObject(Challenge.class))
                .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find active and completed challenges", e);
        }
    }

    public List<Challenge> findByCityNameActiveAndCompleted(String cityName, int limit, Date lastCreatedAt) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                .whereEqualTo("cityName", cityName)
                .whereIn("status", java.util.Arrays.asList(ChallengeStatus.ACTIVE.name(), ChallengeStatus.COMPLETED.name()))
                .orderBy("createdAt", Query.Direction.DESCENDING);

            if (lastCreatedAt != null) {
                query = query.startAfter(lastCreatedAt);
            }

            var docs = query.limit(limit).get().get().getDocuments();
            return docs.stream()
                .map(doc -> doc.toObject(Challenge.class))
                .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by city (active and completed)", e);
        }
    }

    public List<Challenge> findByCreatedBy(String userId, int limit, Date lastCreatedAt) {
        try {
            Query query = firestore.collection(COLLECTION_NAME)
                .whereEqualTo("createdBy", userId)
                .orderBy("createdAt", Query.Direction.DESCENDING);

            if (lastCreatedAt != null) {
                query = query.startAfter(lastCreatedAt);
            }

            var docs = query.limit(limit).get().get().getDocuments();
            return docs.stream()
                .map(doc -> doc.toObject(Challenge.class))
                .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find challenges by creator", e);
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