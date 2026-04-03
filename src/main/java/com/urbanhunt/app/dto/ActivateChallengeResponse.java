package com.urbanhunt.app.dto;

import com.urbanhunt.app.model.Challenge;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ActivateChallengeResponse {
    private Challenge challenge;
    private String confirmationId;
}