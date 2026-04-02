package com.urbanhunt.app.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VersionCheckResponse {
    private Boolean supported;           // true if version is supported
    private Boolean updateRequired;      // true if update is mandatory
    private String latestVersion;        // latest available version
    private String updateMessage;        // message to show user
}