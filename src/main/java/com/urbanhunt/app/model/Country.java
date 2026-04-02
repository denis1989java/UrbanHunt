package com.urbanhunt.app.model;

import com.google.cloud.firestore.annotation.DocumentId;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Country {

    @DocumentId
    private String code; // ES, US, etc.

    private String name; // Spain, United States, etc.

    private List<String> cities;
}