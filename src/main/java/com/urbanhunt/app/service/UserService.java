package com.urbanhunt.app.service;

import com.urbanhunt.app.dto.UpdateProfileRequest;
import com.urbanhunt.app.model.User;
import com.urbanhunt.app.repository.UserRepository;
import com.urbanhunt.app.security.UserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Date;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    public User createOrUpdateUser(UserPrincipal principal) {
        User existingUser = userRepository.findById(principal.getUid());

        if (existingUser != null) {
            // Only update email, provider and lastLoginAt
            // Don't overwrite name and pictureUrl as user may have customized them
            existingUser.setEmail(principal.getEmail());
            existingUser.setProvider(principal.getProvider());
            existingUser.setLastLoginAt(new Date());
            return userRepository.save(existingUser);
        } else {
            // New user - use data from Firebase Auth
            User newUser = User.builder()
                    .id(principal.getUid())
                    .email(principal.getEmail())
                    .name(principal.getName())
                    .pictureUrl(principal.getPicture())
                    .provider(principal.getProvider())
                    .createdAt(new Date())
                    .lastLoginAt(new Date())
                    .build();
            return userRepository.save(newUser);
        }
    }

    public User getUserById(String id) {
        return userRepository.findById(id);
    }

    public User updateProfile(String userId, UpdateProfileRequest request) {
        User user = userRepository.findById(userId);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        user.setName(request.getName());

        if (request.getPictureUrl() != null) {
            user.setPictureUrl(request.getPictureUrl());
        }

        if (request.getSocialMediaUrl() != null) {
            user.setSocialMediaUrl(request.getSocialMediaUrl());
        }

        return userRepository.save(user);
    }
}