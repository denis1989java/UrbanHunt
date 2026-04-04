package com.urbanhunt.app.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateChallengeRequest {

    @NotBlank(message = "Title is required")
    @Size(min = 1, max = 100, message = "Title must be between 1 and 100 characters")
    private String title;

    @Size(max = 500, message = "Description must be less than 500 characters")
    private String description;

    @NotBlank(message = "Country is required")
    @Size(min = 1, max = 50, message = "Country must be between 1 and 50 characters")
    private String country;

    @NotBlank(message = "City is required")
    @Size(min = 1, max = 50, message = "City must be between 1 and 50 characters")
    private String cityName;

    @Size(max = 200, message = "Location must be less than 200 characters")
    private String location; // Private note for creator

    private String prizePhotoUrl; // Optional prize photo URL
}