package com.urbanhunt.app.security;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserPrincipal {

    private String uid;

    private String email;

    private String name;

    private String picture;

    private String provider;

}