package com.urbanhunt.app.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.google.cloud.firestore.annotation.DocumentId;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Challenge {

    @DocumentId
    private String id;

    private String title;

    private ChallengeStatus status;

    private String country;

    private String cityName;

    private String createdBy; // Email of user who created the challenge

    private String prizePhotoUrl; // Optional photo of the prize

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private Date createdAt;

    @Builder.Default
    private List<Hint> hints = new ArrayList<>();

    private Completion completion;

    private Long commentsCount;

    public enum ChallengeStatus {
        ACTIVE,
        COMPLETED,
        ARCHIVED
    }

}