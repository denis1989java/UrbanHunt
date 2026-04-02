package com.urbanhunt.app.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {

    @NotBlank(message = "Name is required")
    @Size(min = 1, max = 20, message = "Name must be between 1 and 20 characters")
    private String name;

    private String pictureUrl;

    @Size(max = 500, message = "Social media URL must be less than 500 characters")
    private String socialMediaUrl;
}
