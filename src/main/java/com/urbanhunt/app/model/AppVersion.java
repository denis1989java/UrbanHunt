package com.urbanhunt.app.model;

import com.google.cloud.firestore.annotation.DocumentId;
import com.google.cloud.spring.data.firestore.Document;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Document(collectionName = "app_versions")
public class AppVersion {

    @DocumentId
    private String id;

    /**
     * Platform: "ios" or "android"
     */
    private String platform;

    /**
     * Minimum supported version (e.g., "1.0.0")
     * Versions below this will be forced to update
     */
    private String minSupportedVersion;

    /**
     * Latest available version (e.g., "1.2.0")
     */
    private String latestVersion;

    /**
     * Update message shown to users (can be localized)
     */
    private String updateMessage;

    /**
     * Whether update is mandatory
     */
    private Boolean forcedUpdate;
}