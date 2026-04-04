package com.urbanhunt.app.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Completion;
import com.urbanhunt.app.model.Hint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ChallengeDto {

    private String id;
    private String title;
    private Challenge.ChallengeStatus status;
    private String country;
    private String cityName;
    private String createdBy;
    private UserSummary creator;
    private String location; // Only visible to creator
    private String prizePhotoUrl;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private Date createdAt;
    private List<Hint> hints;
    private Completion completion;
    private Long commentsCount;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private Date nextHintDate;
    private String confirmationId; // Prize confirmation ID for QR code

}