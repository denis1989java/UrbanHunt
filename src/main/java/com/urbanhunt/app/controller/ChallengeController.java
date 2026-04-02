package com.urbanhunt.app.controller;

import com.urbanhunt.app.dto.ChallengeDto;
import com.urbanhunt.app.dto.CreateChallengeRequest;
import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Challenge.ChallengeStatus;
import com.urbanhunt.app.model.Completion;
import com.urbanhunt.app.model.Hint;
import com.urbanhunt.app.security.SecurityUtils;
import com.urbanhunt.app.security.UserPrincipal;
import com.urbanhunt.app.service.ChallengeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/challenges")
@RequiredArgsConstructor
public class ChallengeController {

    private final ChallengeService challengeService;

    @PostMapping
    public ResponseEntity<Challenge> createChallenge(@Valid @RequestBody CreateChallengeRequest request) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        Challenge challenge = Challenge.builder()
                .title(request.getTitle())
                .status(ChallengeStatus.ACTIVE)
                .country(request.getCountry())
                .cityName(request.getCityName())
                .createdBy(principal.getUid()) // Set creator userId instead of email
                .prizePhotoUrl(request.getPrizePhotoUrl()) // Set prize photo
                .createdAt(new Date())
                .commentsCount(0L)
                .build();

        Challenge created = challengeService.createChallenge(challenge);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ChallengeDto> getChallengeById(@PathVariable String id) {
        Challenge challenge = challengeService.getChallengeById(id);
        if (challenge == null) {
            return ResponseEntity.notFound().build();
        }

        ChallengeDto dto = ChallengeDto.builder()
                .id(challenge.getId())
                .title(challenge.getTitle())
                .status(challenge.getStatus())
                .country(challenge.getCountry())
                .cityName(challenge.getCityName())
                .createdBy(challenge.getCreatedBy())
                .creator(challenge.getCreatedBy() != null
                    ? challengeService.getCreatorInfo(challenge.getCreatedBy())
                    : null)
                .prizePhotoUrl(challenge.getPrizePhotoUrl())
                .createdAt(challenge.getCreatedAt())
                .hints(challengeService.getPublishedHints(challenge))
                .completion(challenge.getCompletion())
                .commentsCount(challenge.getCommentsCount())
                .build();
        return ResponseEntity.ok(dto);
    }

    @GetMapping
    public List<ChallengeDto> getAllChallenges(
            @RequestParam(required = false) String city,
            @RequestParam(required = false) ChallengeStatus status) {

        List<Challenge> challenges;
        if (city != null && status != null) {
            challenges = challengeService.getActiveChallengesByCity(city);
        } else if (city != null) {
            challenges = challengeService.getChallengesByCity(city);
        } else if (status != null) {
            challenges = challengeService.getActiveChallenges();
        } else {
            challenges = challengeService.getAllChallenges();
        }

        return challenges.stream()
                .map(challenge -> {
                    var builder = ChallengeDto.builder()
                            .id(challenge.getId())
                            .title(challenge.getTitle())
                            .status(challenge.getStatus())
                            .country(challenge.getCountry())
                            .cityName(challenge.getCityName())
                            .createdBy(challenge.getCreatedBy())
                            .prizePhotoUrl(challenge.getPrizePhotoUrl())
                            .createdAt(challenge.getCreatedAt())
                            .hints(challengeService.getPublishedHints(challenge))
                            .completion(challenge.getCompletion())
                            .commentsCount(challenge.getCommentsCount());

                    // Add creator info if available
                    if (challenge.getCreatedBy() != null) {
                        builder.creator(challengeService.getCreatorInfo(challenge.getCreatedBy()));
                    }

                    return builder.build();
                })
                .collect(Collectors.toList());
    }

    @PostMapping("/{id}/hints")
    public ResponseEntity<Challenge> addHint(
            @PathVariable String id,
            @RequestBody Hint hint) {
        Challenge challenge = challengeService.addHint(id, hint);
        if (challenge == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(challenge);
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<Challenge> completeChallenge(
            @PathVariable String id,
            @RequestBody Completion completion) {
        Challenge challenge = challengeService.completeChallenge(id, completion);
        if (challenge == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(challenge);
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<Challenge> updateStatus(
            @PathVariable String id,
            @RequestParam ChallengeStatus status) {
        Challenge challenge = challengeService.updateChallengeStatus(id, status);
        if (challenge == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(challenge);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteChallenge(@PathVariable String id) {
        challengeService.deleteChallenge(id);
        return ResponseEntity.noContent().build();
    }

}