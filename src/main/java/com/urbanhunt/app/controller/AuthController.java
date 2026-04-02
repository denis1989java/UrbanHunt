package com.urbanhunt.app.controller;

import com.urbanhunt.app.dto.UpdateProfileRequest;
import com.urbanhunt.app.model.User;
import com.urbanhunt.app.security.SecurityUtils;
import com.urbanhunt.app.security.UserPrincipal;
import com.urbanhunt.app.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;

    @GetMapping("/me")
    public ResponseEntity<User> getCurrentUser() {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        User user = userService.getUserById(principal.getUid());
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(user);
    }

    @PostMapping("/sync")
    public ResponseEntity<User> syncUser() {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        User user = userService.createOrUpdateUser(principal);
        return ResponseEntity.ok(user);
    }

    @PatchMapping("/profile")
    public ResponseEntity<User> updateProfile(@Valid @RequestBody UpdateProfileRequest request) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        User user = userService.updateProfile(principal.getUid(), request);
        return ResponseEntity.ok(user);
    }

}