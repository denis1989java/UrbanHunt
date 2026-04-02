package com.urbanhunt.app.controller;

import com.urbanhunt.app.dto.VersionCheckRequest;
import com.urbanhunt.app.dto.VersionCheckResponse;
import com.urbanhunt.app.model.AppVersion;
import com.urbanhunt.app.service.VersionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/version")
@RequiredArgsConstructor
public class VersionController {

    private final VersionService versionService;

    @PostMapping("/check")
    public ResponseEntity<VersionCheckResponse> checkVersion(@RequestBody VersionCheckRequest request) {
        AppVersion versionInfo = versionService.getVersionInfo(request.getPlatform());

        if (versionInfo == null) {
            // No version check configured for this platform - allow all versions
            return ResponseEntity.ok(VersionCheckResponse.builder()
                    .supported(true)
                    .updateRequired(false)
                    .build());
        }

        boolean isSupported = versionService.isVersionSupported(
                request.getVersion(),
                versionInfo.getMinSupportedVersion()
        );

        return ResponseEntity.ok(VersionCheckResponse.builder()
                .supported(isSupported)
                .updateRequired(!isSupported && Boolean.TRUE.equals(versionInfo.getForcedUpdate()))
                .latestVersion(versionInfo.getLatestVersion())
                .updateMessage(versionInfo.getUpdateMessage())
                .build());
    }
}