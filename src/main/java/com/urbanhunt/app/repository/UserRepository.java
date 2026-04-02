package com.urbanhunt.app.repository;

import com.google.cloud.firestore.Firestore;
import com.urbanhunt.app.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.concurrent.ExecutionException;

@Repository
@RequiredArgsConstructor
public class UserRepository {

    private final Firestore firestore;
    private static final String COLLECTION_NAME = "users";

    public User save(User user) {
        try {
            String id = user.getId();
            if (id == null) {
                id = firestore.collection(COLLECTION_NAME).document().getId();
                user.setId(id);
            }
            firestore.collection(COLLECTION_NAME).document(id).set(user).get();
            return user;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to save user", e);
        }
    }

    public User findById(String id) {
        try {
            var doc = firestore.collection(COLLECTION_NAME).document(id).get().get();
            return doc.exists() ? doc.toObject(User.class) : null;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find user", e);
        }
    }

    public User findByEmail(String email) {
        try {
            var query = firestore.collection(COLLECTION_NAME)
                    .whereEqualTo("email", email)
                    .limit(1)
                    .get()
                    .get();

            if (query.isEmpty()) {
                return null;
            }

            return query.getDocuments().get(0).toObject(User.class);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to find user by email", e);
        }
    }

}