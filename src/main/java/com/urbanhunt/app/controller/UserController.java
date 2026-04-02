package com.urbanhunt.app.controller;

import com.urbanhunt.app.dto.UserSummary;
import com.urbanhunt.app.model.User;
import com.urbanhunt.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/{userId}")
    public ResponseEntity<UserSummary> getUserById(@PathVariable String userId) {
        User user = userRepository.findById(userId);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }

        UserSummary summary = UserSummary.builder()
                .email(user.getEmail())
                .name(user.getName())
                .pictureUrl(user.getPictureUrl())
                .socialMediaUrl(user.getSocialMediaUrl())
                .build();

        return ResponseEntity.ok(summary);
    }
}