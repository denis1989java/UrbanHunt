package com.urbanhunt.app.repository;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.Query;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.urbanhunt.app.model.PrizeConfirmation;
import com.urbanhunt.app.model.PrizeConfirmation.ConfirmationStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.Date;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class PrizeConfirmationRepository {

    private final Firestore firestore;
    private static final String COLLECTION_NAME = "prizeConfirmations";

    public PrizeConfirmation save(PrizeConfirmation confirmation) {
        try {
            if (confirmation.getId() == null) {
                confirmation.setId(firestore.collection(COLLECTION_NAME).document().getId());
            }
            firestore.collection(COLLECTION_NAME)
                    .document(confirmation.getId())
                    .set(confirmation)
                    .get();
            return confirmation;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error saving prize confirmation", e);
        }
    }

    public PrizeConfirmation findById(String id) {
        try {
            var doc = firestore.collection(COLLECTION_NAME)
                    .document(id)
                    .get()
                    .get();
            if (!doc.exists()) {
                return null;
            }
            return doc.toObject(PrizeConfirmation.class);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error finding prize confirmation", e);
        }
    }

    public PrizeConfirmation findByChallengeId(String challengeId) {
        try {
            var querySnapshot = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("challengeId", challengeId)
                    .limit(1)
                    .get()
                    .get();

            if (querySnapshot.isEmpty()) {
                return null;
            }

            return querySnapshot.getDocuments().get(0).toObject(PrizeConfirmation.class);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error finding prize confirmation by challenge", e);
        }
    }

    public List<PrizeConfirmation> findByUserId(String userId) {
        try {
            var querySnapshot = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("userId", userId)
                    .orderBy("createdAt", Query.Direction.DESCENDING)
                    .get()
                    .get();

            return querySnapshot.getDocuments().stream()
                    .map(doc -> doc.toObject(PrizeConfirmation.class))
                    .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error finding prize confirmations by user", e);
        }
    }
}