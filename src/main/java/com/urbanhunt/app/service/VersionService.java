package com.urbanhunt.app.service;

import com.urbanhunt.app.model.AppVersion;
import com.urbanhunt.app.repository.AppVersionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutionException;

@Service
@RequiredArgsConstructor
public class VersionService {

    private final AppVersionRepository appVersionRepository;

    /**
     * Get version info for a platform
     * @param platform "ios" or "android"
     * @return AppVersion or null if not found
     */
    public AppVersion getVersionInfo(String platform) {
        try {
            return appVersionRepository.findAll()
                    .collectList()
                    .toFuture()
                    .get()
                    .stream()
                    .filter(v -> platform.equalsIgnoreCase(v.getPlatform()))
                    .findFirst()
                    .orElse(null);
        } catch (InterruptedException | ExecutionException e) {
            System.err.println("Error fetching version info: " + e.getMessage());
            return null;
        }
    }

    /**
     * Check if version is supported
     * @param currentVersion Current app version (e.g., "1.0.0")
     * @param minVersion Minimum supported version (e.g., "1.0.0")
     * @return true if current version >= min version
     */
    public boolean isVersionSupported(String currentVersion, String minVersion) {
        if (currentVersion == null || minVersion == null) {
            return true; // If no version check configured, allow
        }

        try {
            return compareVersions(currentVersion, minVersion) >= 0;
        } catch (Exception e) {
            System.err.println("Error comparing versions: " + e.getMessage());
            return true; // On error, allow to avoid blocking users
        }
    }

    /**
     * Compare two semantic versions
     * @param version1 First version (e.g., "1.2.3")
     * @param version2 Second version (e.g., "1.0.5")
     * @return negative if v1 < v2, 0 if equal, positive if v1 > v2
     */
    private int compareVersions(String version1, String version2) {
        String[] parts1 = version1.split("\\.");
        String[] parts2 = version2.split("\\.");

        int maxLength = Math.max(parts1.length, parts2.length);

        for (int i = 0; i < maxLength; i++) {
            int v1 = i < parts1.length ? Integer.parseInt(parts1[i]) : 0;
            int v2 = i < parts2.length ? Integer.parseInt(parts2[i]) : 0;

            if (v1 != v2) {
                return Integer.compare(v1, v2);
            }
        }

        return 0; // Versions are equal
    }
}