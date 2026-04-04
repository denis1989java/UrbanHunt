package com.urbanhunt.app.service;

import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Challenge.ChallengeStatus;
import com.urbanhunt.app.model.Completion;
import com.urbanhunt.app.model.PrizeConfirmation;
import com.urbanhunt.app.model.PrizeConfirmation.ConfirmationStatus;
import com.urbanhunt.app.repository.PrizeConfirmationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PrizeConfirmationService {

    private final PrizeConfirmationRepository prizeConfirmationRepository;
    private final ChallengeService challengeService;

    /**
     * Create a new prize confirmation when challenge is activated
     */
    public PrizeConfirmation createConfirmation(String challengeId) {
        // Check if confirmation already exists
        PrizeConfirmation existing = prizeConfirmationRepository.findByChallengeId(challengeId);
        if (existing != null) {
            return existing;
        }

        PrizeConfirmation confirmation = PrizeConfirmation.builder()
                .challengeId(challengeId)
                .status(ConfirmationStatus.NEW)
                .createdAt(new Date())
                .build();

        return prizeConfirmationRepository.save(confirmation);
    }

    /**
     * Confirm prize finding by user using confirmationId
     */
    public PrizeConfirmation confirmPrizeById(String confirmationId, String userId, String message, String contentUrl) {
        PrizeConfirmation confirmation = prizeConfirmationRepository.findById(confirmationId);
        if (confirmation == null) {
            throw new RuntimeException("Prize confirmation not found: " + confirmationId);
        }

        if (confirmation.getStatus() == ConfirmationStatus.DONE) {
            throw new RuntimeException("Prize already confirmed");
        }

        // Update confirmation
        confirmation.setUserId(userId);
        confirmation.setStatus(ConfirmationStatus.DONE);
        confirmation.setMessage(message);
        confirmation.setContentUrl(contentUrl);
        confirmation.setConfirmedAt(new Date());

        PrizeConfirmation saved = prizeConfirmationRepository.save(confirmation);

        // Create completion object and complete the challenge
        Completion completion = Completion.builder()
                .userId(userId)
                .completedAt(new Date())
                .build();

        challengeService.completeChallenge(confirmation.getChallengeId(), completion);

        return saved;
    }

    /**
     * Confirm prize finding by user using challengeId (legacy method)
     */
    public PrizeConfirmation confirmPrize(String challengeId, String userId, String message, String contentUrl) {
        PrizeConfirmation confirmation = prizeConfirmationRepository.findByChallengeId(challengeId);
        if (confirmation == null) {
            throw new RuntimeException("Prize confirmation not found for challenge: " + challengeId);
        }

        if (confirmation.getStatus() == ConfirmationStatus.DONE) {
            throw new RuntimeException("Prize already confirmed for this challenge");
        }

        // Update confirmation
        confirmation.setUserId(userId);
        confirmation.setStatus(ConfirmationStatus.DONE);
        confirmation.setMessage(message);
        confirmation.setContentUrl(contentUrl);
        confirmation.setConfirmedAt(new Date());

        PrizeConfirmation saved = prizeConfirmationRepository.save(confirmation);

        // Create completion object and complete the challenge
        Completion completion = Completion.builder()
                .userId(userId)
                .completedAt(new Date())
                .build();

        challengeService.completeChallenge(challengeId, completion);

        return saved;
    }

    public PrizeConfirmation getConfirmationById(String confirmationId) {
        return prizeConfirmationRepository.findById(confirmationId);
    }

    public PrizeConfirmation getConfirmationByChallengeId(String challengeId) {
        return prizeConfirmationRepository.findByChallengeId(challengeId);
    }

    public List<PrizeConfirmation> getConfirmationsByUserId(String userId) {
        return prizeConfirmationRepository.findByUserId(userId);
    }
}