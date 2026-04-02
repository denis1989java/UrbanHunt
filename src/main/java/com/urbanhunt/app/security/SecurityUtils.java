package com.urbanhunt.app.security;

import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class SecurityUtils {

    public static UserPrincipal getCurrentUser() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserPrincipal) {
            return (UserPrincipal) authentication.getPrincipal();
        }
        return null;
    }

    public static String getCurrentUserId() {
        UserPrincipal user = getCurrentUser();
        return user != null ? user.getUid() : null;
    }

    public static boolean isAuthenticated() {
        return getCurrentUser() != null;
    }

}