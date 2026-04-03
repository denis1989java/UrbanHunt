package com.urbanhunt.app.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PrizeConfirmation {

    private String id;
    private String challengeId;
    private String userId; // User who found the prize
    private ConfirmationStatus status;
    private String message; // Optional text message
    private String contentUrl; // Optional photo or video URL
    private Date createdAt;
    private Date confirmedAt; // When status changed to DONE

    public enum ConfirmationStatus {
        NEW,
        DONE
    }
}