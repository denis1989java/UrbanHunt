package com.urbanhunt.app.repository;

import com.google.cloud.spring.data.firestore.FirestoreReactiveRepository;
import com.urbanhunt.app.model.Locale;
import org.springframework.stereotype.Repository;

@Repository
public interface LocaleRepository extends FirestoreReactiveRepository<Locale> {
}