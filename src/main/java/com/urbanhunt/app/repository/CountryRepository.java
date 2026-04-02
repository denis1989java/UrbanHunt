package com.urbanhunt.app.repository;

import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QueryDocumentSnapshot;
import com.urbanhunt.app.model.Country;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.stream.Collectors;

@Repository
@RequiredArgsConstructor
public class CountryRepository {

    private static final String COLLECTION_NAME = "countries";

    private final Firestore firestore;

    public List<Country> findAll() {
        try {
            return firestore.collection(COLLECTION_NAME)
                    .get()
                    .get()
                    .getDocuments()
                    .stream()
                    .map(doc -> doc.toObject(Country.class))
                    .collect(Collectors.toList());
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to fetch countries", e);
        }
    }

    public Country findByCode(String code) {
        try {
            QueryDocumentSnapshot doc = (QueryDocumentSnapshot) firestore.collection(COLLECTION_NAME)
                    .document(code)
                    .get()
                    .get();

            if (!doc.exists()) {
                return null;
            }

            return doc.toObject(Country.class);
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to fetch country", e);
        }
    }
}