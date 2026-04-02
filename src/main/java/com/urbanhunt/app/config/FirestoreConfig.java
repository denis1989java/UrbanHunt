package com.urbanhunt.app.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.FirestoreOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Configuration
public class FirestoreConfig {

    @Value("${spring.cloud.gcp.project-id}")
    private String projectId;

    @Value("${spring.cloud.gcp.firestore.database-id:(default)}")
    private String databaseId;

    @Bean
    public Firestore firestore() throws IOException {
        String emulatorHost = System.getenv("FIRESTORE_EMULATOR_HOST");

        if (emulatorHost != null && !emulatorHost.isEmpty()) {
            System.out.println("🔧 Using Firestore Emulator at: " + emulatorHost);
            FirestoreOptions options = FirestoreOptions.newBuilder()
                    .setProjectId(projectId)
                    .setEmulatorHost(emulatorHost)
                    .build();
            return options.getService();
        }

        System.out.println("☁️ Using Production Firestore with project: " + projectId + ", database: " + databaseId);
        FirestoreOptions options = FirestoreOptions.newBuilder()
                .setProjectId(projectId)
                .setDatabaseId(databaseId)
                .setCredentials(GoogleCredentials.getApplicationDefault())
                .build();

        return options.getService();
    }

}