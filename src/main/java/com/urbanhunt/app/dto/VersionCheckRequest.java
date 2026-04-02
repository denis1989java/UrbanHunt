package com.urbanhunt.app.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VersionCheckRequest {
    private String platform; // "ios" or "android"
    private String version;  // "1.0.0"
}