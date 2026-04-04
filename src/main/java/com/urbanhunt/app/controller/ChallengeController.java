package com.urbanhunt.app.controller;

import com.urbanhunt.app.dto.ActivateChallengeResponse;
import com.urbanhunt.app.dto.ChallengeDto;
import com.urbanhunt.app.dto.CreateChallengeRequest;
import com.urbanhunt.app.dto.UpdateChallengeRequest;
import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Challenge.ChallengeStatus;
import com.urbanhunt.app.model.Completion;
import com.urbanhunt.app.model.Hint;
import com.urbanhunt.app.model.PrizeConfirmation;
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
import java.util.Map;
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
                .location(request.getLocation()) // Set private location note
                .prizePhotoUrl(request.getPrizePhotoUrl()) // Set prize photo
                .createdAt(new Date())
                .commentsCount(0L)
                .build();

        Challenge created = challengeService.createChallenge(challenge);

        // Create prize confirmation immediately upon challenge creation
        PrizeConfirmation confirmation = prizeConfirmationService.createConfirmation(created.getId());

        // Convert to DTO with nextHintDate and confirmationId
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
                .location(created.getLocation()) // Always include for creator
                .prizePhotoUrl(created.getPrizePhotoUrl())
                .createdAt(created.getCreatedAt())
                .hints(challengeService.getPublishedHints(created))
                .completion(created.getCompletion())
                .commentsCount(created.getCommentsCount())
                .nextHintDate(challengeService.getNextHintDate(created))
                .confirmationId(confirmation.getId()) // Include confirmationId
                .build();

        return ResponseEntity.status(HttpStatus.CREATED).body(dto);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ChallengeDto> getChallengeById(@PathVariable String id) {
        Challenge challenge = challengeService.getChallengeById(id);
        if (challenge == null) {
            return ResponseEntity.notFound().build();
        }

        UserPrincipal principal = SecurityUtils.getCurrentUser();
        boolean isCreator = principal != null && principal.getUid().equals(challenge.getCreatedBy());

        // Get confirmation ID if user is creator
        String confirmationId = null;
        if (isCreator) {
            PrizeConfirmation confirmation = prizeConfirmationService.getConfirmationByChallengeId(challenge.getId());
            if (confirmation != null) {
                confirmationId = confirmation.getId();
            }
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
                .location(isCreator ? challenge.getLocation() : null) // Only for creator
                .prizePhotoUrl(challenge.getPrizePhotoUrl())
                .createdAt(challenge.getCreatedAt())
                .hints(challengeService.getPublishedHints(challenge))
                .completion(challenge.getCompletion())
                .commentsCount(challenge.getCommentsCount())
                .nextHintDate(challengeService.getNextHintDate(challenge))
                .confirmationId(confirmationId) // Include confirmationId for creator
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
                    // Get confirmation ID for completed challenges
                    String confirmationId = null;
                    if (challenge.getStatus() == ChallengeStatus.COMPLETED) {
                        PrizeConfirmation confirmation = prizeConfirmationService.getConfirmationByChallengeId(challenge.getId());
                        if (confirmation != null) {
                            confirmationId = confirmation.getId();
                        }
                    }

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
                            .nextHintDate(challengeService.getNextHintDate(challenge))
                            .confirmationId(confirmationId); // Include confirmationId for completed challenges

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
    public ResponseEntity<?> updateStatus(
            @PathVariable String id,
            @RequestParam ChallengeStatus status) {
        Challenge oldChallenge = challengeService.getChallengeById(id);
        if (oldChallenge == null) {
            return ResponseEntity.notFound().build();
        }

        // Validate: cannot activate challenge without hints
        if (status == ChallengeStatus.ACTIVE &&
            (oldChallenge.getHints() == null || oldChallenge.getHints().isEmpty())) {
            return ResponseEntity.badRequest()
                .body(Map.of("error", "Cannot activate challenge without hints. Please add at least one hint."));
        }

        // Validate: cannot deactivate or update challenge to remove all hints if currently active
        if (oldChallenge.getStatus() == ChallengeStatus.ACTIVE &&
            status != ChallengeStatus.ACTIVE) {
            // Allow status change, this validation is only for hint deletion
        }

        ChallengeStatus oldStatus = oldChallenge.getStatus();
        Challenge challenge = challengeService.updateChallengeStatus(id, status);

        // Create prize confirmation when challenge is activated
        if (oldStatus != ChallengeStatus.ACTIVE && status == ChallengeStatus.ACTIVE) {
            PrizeConfirmation confirmation = prizeConfirmationService.createConfirmation(id);
            // Return special response with confirmationId for activation
            ActivateChallengeResponse response = ActivateChallengeResponse.builder()
                    .challenge(challenge)
                    .confirmationId(confirmation.getId())
                    .build();
            return ResponseEntity.ok(response);
        }

        return ResponseEntity.ok(challenge);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateChallenge(
            @PathVariable String id,
            @Valid @RequestBody UpdateChallengeRequest request) {
        UserPrincipal principal = SecurityUtils.getCurrentUser();
        if (principal == null) {
            return ResponseEntity.status(401).build();
        }

        try {
            Challenge challenge = challengeService.updateChallenge(
                    id,
                    request.getTitle(),
                    request.getCountry(),
                    request.getCityName(),
                    request.getLocation(),
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
                    .location(challenge.getLocation()) // Include location for creator
                    .prizePhotoUrl(challenge.getPrizePhotoUrl())
                    .createdAt(challenge.getCreatedAt())
                    .hints(challengeService.getPublishedHints(challenge))
                    .completion(challenge.getCompletion())
                    .commentsCount(challenge.getCommentsCount())
                    .nextHintDate(challengeService.getNextHintDate(challenge))
                    .build();

            return ResponseEntity.ok(dto);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
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
                    // Get confirmation ID for creator's own challenges
                    PrizeConfirmation confirmation = prizeConfirmationService.getConfirmationByChallengeId(challenge.getId());
                    String confirmationId = confirmation != null ? confirmation.getId() : null;

                    var builder = ChallengeDto.builder()
                            .id(challenge.getId())
                            .title(challenge.getTitle())
                            .status(challenge.getStatus())
                            .country(challenge.getCountry())
                            .cityName(challenge.getCityName())
                            .createdBy(challenge.getCreatedBy())
                            .location(challenge.getLocation()) // Always include for creator's own challenges
                            .prizePhotoUrl(challenge.getPrizePhotoUrl())
                            .createdAt(challenge.getCreatedAt())
                            .hints(challengeService.getPublishedHints(challenge))
                            .completion(challenge.getCompletion())
                            .commentsCount(challenge.getCommentsCount())
                            .nextHintDate(challengeService.getNextHintDate(challenge))
                            .confirmationId(confirmationId); // Include confirmationId for creator

                    if (challenge.getCreatedBy() != null) {
                        builder.creator(challengeService.getCreatorInfo(challenge.getCreatedBy()));
                    }

                    return builder.build();
                })
                .collect(Collectors.toList());
    }

}