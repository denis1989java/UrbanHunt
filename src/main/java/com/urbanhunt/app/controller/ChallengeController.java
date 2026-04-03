package com.urbanhunt.app.controller;

import com.urbanhunt.app.dto.ChallengeDto;
import com.urbanhunt.app.dto.CreateChallengeRequest;
import com.urbanhunt.app.dto.UpdateChallengeRequest;
import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Challenge.ChallengeStatus;
import com.urbanhunt.app.model.Completion;
import com.urbanhunt.app.model.Hint;
import com.urbanhunt.app.security.SecurityUtils;
import com.urbanhunt.app.security.UserPrincipal;
import com.urbanhunt.app.service.ChallengeService;
import com.urbanhunt.app.service.PrizeConfirmationService;
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
    private final PrizeConfirmationService prizeConfirmationService;

    @PostMapping
    public ResponseEntity<ChallengeDto> createChallenge(@Valid @RequestBody CreateChallengeRequest request) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        Challenge challenge = Challenge.builder()
                .title(request.getTitle())
                .country(request.getCountry())
                .cityName(request.getCityName())
                .createdBy(principal.getUid()) // Set creator userId instead of email
                .prizePhotoUrl(request.getPrizePhotoUrl()) // Set prize photo
                .createdAt(new Date())
                .commentsCount(0L)
                .build();

        Challenge created = challengeService.createChallenge(challenge);

        // Convert to DTO with nextHintDate
        ChallengeDto dto = ChallengeDto.builder()
                .id(created.getId())
                .title(created.getTitle())
                .status(created.getStatus())
                .country(created.getCountry())
                .cityName(created.getCityName())
                .createdBy(created.getCreatedBy())
                .creator(created.getCreatedBy() != null
                    ? challengeService.getCreatorInfo(created.getCreatedBy())
                    : null)
                .prizePhotoUrl(created.getPrizePhotoUrl())
                .createdAt(created.getCreatedAt())
                .hints(challengeService.getPublishedHints(created))
                .completion(created.getCompletion())
                .commentsCount(created.getCommentsCount())
                .nextHintDate(challengeService.getNextHintDate(created))
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
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
                .nextHintDate(challengeService.getNextHintDate(challenge))
                .build();
        return ResponseEntity.ok(dto);
    }

    @GetMapping
    public List<ChallengeDto> getAllChallenges(
            @RequestParam(required = false) String city,
            @RequestParam(required = false) ChallengeStatus status,
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(required = false) String lastCreatedAt) {

        Date lastDate = null;
        if (lastCreatedAt != null && !lastCreatedAt.isEmpty()) {
            try {
                // Parse ISO date format
                java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                sdf.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
                lastDate = sdf.parse(lastCreatedAt);
            } catch (Exception e) {
                // If parsing fails, ignore and start from beginning
            }
        }

        List<Challenge> challenges;
        if (city != null && status != null) {
            challenges = challengeService.getChallengesByCityAndStatus(city, status, limit, lastDate);
        } else if (city != null) {
            challenges = challengeService.getChallengesByCityActiveAndCompleted(city, limit, lastDate);
        } else if (status != null) {
            challenges = challengeService.getChallengesByStatus(status, limit, lastDate);
        } else {
            challenges = challengeService.getActiveAndCompletedChallenges(limit, lastDate);
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
                            .commentsCount(challenge.getCommentsCount())
                            .nextHintDate(challengeService.getNextHintDate(challenge));

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
        Challenge oldChallenge = challengeService.getChallengeById(id);
        if (oldChallenge == null) {
            return ResponseEntity.notFound().build();
        }

        ChallengeStatus oldStatus = oldChallenge.getStatus();
        Challenge challenge = challengeService.updateChallengeStatus(id, status);

        // Create prize confirmation when challenge is activated
        if (oldStatus != ChallengeStatus.ACTIVE && status == ChallengeStatus.ACTIVE) {
            prizeConfirmationService.createConfirmation(id);
        }

        return ResponseEntity.ok(challenge);
    }

    @PutMapping("/{id}")
    public ResponseEntity<ChallengeDto> updateChallenge(
            @PathVariable String id,
            @Valid @RequestBody UpdateChallengeRequest request) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        Challenge challenge = challengeService.updateChallenge(
                id,
                request.getTitle(),
                request.getCountry(),
                request.getCityName(),
                request.getPrizePhotoUrl()
        );

        if (challenge == null) {
            return ResponseEntity.notFound().build();
        }

        // Convert to DTO
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
                .nextHintDate(challengeService.getNextHintDate(challenge))
                .build();

        return ResponseEntity.ok(dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteChallenge(@PathVariable String id) {
        challengeService.deleteChallenge(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/my")
    public List<ChallengeDto> getMyChallenges(
            @RequestParam(defaultValue = "20") int limit,
            @RequestParam(required = false) String lastCreatedAt) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return List.of();
        }

        Date lastDate = null;
        if (lastCreatedAt != null && !lastCreatedAt.isEmpty()) {
            try {
                java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                sdf.setTimeZone(java.util.TimeZone.getTimeZone("UTC"));
                lastDate = sdf.parse(lastCreatedAt);
            } catch (Exception e) {
                // If parsing fails, ignore and start from beginning
            }
        }

        List<Challenge> challenges = challengeService.getChallengesByCreator(principal.getUid(), limit, lastDate);

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
                            .commentsCount(challenge.getCommentsCount())
                            .nextHintDate(challengeService.getNextHintDate(challenge));

                    if (challenge.getCreatedBy() != null) {
                        builder.creator(challengeService.getCreatorInfo(challenge.getCreatedBy()));
                    }

                    return builder.build();
                })
                .collect(Collectors.toList());
    }

}