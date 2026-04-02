package com.urbanhunt.app.repository;

import com.google.cloud.spring.data.firestore.FirestoreReactiveRepository;
import com.urbanhunt.app.model.AppVersion;
import org.springframework.stereotype.Repository;

@Repository
public interface AppVersionRepository extends FirestoreReactiveRepository<AppVersion> {
}