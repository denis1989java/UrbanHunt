package com.urbanhunt.app.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConfirmPrizeRequest {
    private String message; // Optional
    private String contentUrl; // Optional photo or video URL
}