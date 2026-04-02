package com.urbanhunt.app.service;

import com.urbanhunt.app.dto.UserSummary;
import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Challenge.ChallengeStatus;
import com.urbanhunt.app.model.Completion;
import com.urbanhunt.app.model.Hint;
import com.urbanhunt.app.model.User;
import com.urbanhunt.app.repository.ChallengeRepository;
import com.urbanhunt.app.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ChallengeService {

    private final ChallengeRepository challengeRepository;
    private final ProfanityFilterService profanityFilterService;
    private final UserRepository userRepository;

    public Challenge createChallenge(Challenge challenge) {
        // Validate challenge title for profanity
        profanityFilterService.validateText(challenge.getTitle(), "challenge title");

        if (challenge.getCreatedAt() == null) {
            challenge.setCreatedAt(new Date());
        }
        if (challenge.getStatus() == null) {
            challenge.setStatus(ChallengeStatus.ACTIVE);
        }
        if (challenge.getCommentsCount() == null) {
            challenge.setCommentsCount(0L);
        }
        return challengeRepository.save(challenge);
    }

    public Challenge getChallengeById(String id) {
        return challengeRepository.findById(id);
    }

    public List<Challenge> getAllChallenges(int limit, Date lastCreatedAt) {
        return challengeRepository.findAll(limit, lastCreatedAt);
    }

    public List<Challenge> getChallengesByStatus(ChallengeStatus status, int limit, Date lastCreatedAt) {
        return challengeRepository.findByStatus(status, limit, lastCreatedAt);
    }

    public List<Challenge> getChallengesByCity(String cityName, int limit, Date lastCreatedAt) {
        return challengeRepository.findByCityName(cityName, limit, lastCreatedAt);
    }

    public List<Challenge> getChallengesByCityAndStatus(String cityName, ChallengeStatus status, int limit, Date lastCreatedAt) {
        return challengeRepository.findByCityNameAndStatus(cityName, status, limit, lastCreatedAt);
    }

    public Challenge addHint(String challengeId, Hint hint) {
        // Validate that hint has either content or link
        if ((hint.getContent() == null || hint.getContent().trim().isEmpty()) &&
            (hint.getLink() == null || hint.getLink().trim().isEmpty())) {
            throw new IllegalArgumentException("Hint must have either text content or a photo/video");
        }

        // Validate hint text for profanity
        if (hint.getContent() != null && !hint.getContent().trim().isEmpty()) {
            profanityFilterService.validateText(hint.getContent(), "hint text");
        }

        Challenge challenge = challengeRepository.findById(challengeId);
        if (challenge == null) {
            return null;
        }
        if (challenge.getHints() == null) {
            challenge.setHints(new ArrayList<>());
        }
        challenge.getHints().add(hint);
        return challengeRepository.save(challenge);
    }

    public Challenge completeChallenge(String challengeId, Completion completion) {
        if (completion.getCompletedAt() == null) {
            completion.setCompletedAt(new Date());
        }
        Challenge challenge = challengeRepository.findById(challengeId);
        if (challenge == null) {
            return null;
        }
        challenge.setCompletion(completion);
        challenge.setStatus(ChallengeStatus.COMPLETED);
        return challengeRepository.save(challenge);
    }

    public Challenge updateChallengeStatus(String challengeId, ChallengeStatus status) {
        Challenge challenge = challengeRepository.findById(challengeId);
        if (challenge == null) {
            return null;
        }
        challenge.setStatus(status);
        return challengeRepository.save(challenge);
    }

    public void deleteChallenge(String challengeId) {
        challengeRepository.deleteById(challengeId);
    }

    public void incrementCommentsCount(String challengeId) {
        Challenge challenge = challengeRepository.findById(challengeId);
        if (challenge != null) {
            challenge.setCommentsCount(
                (challenge.getCommentsCount() != null ? challenge.getCommentsCount() : 0L) + 1
            );
            challengeRepository.save(challenge);
        }
    }

    public void decrementCommentsCount(String challengeId) {
        Challenge challenge = challengeRepository.findById(challengeId);
        if (challenge != null) {
            long count = challenge.getCommentsCount() != null ? challenge.getCommentsCount() : 0L;
            challenge.setCommentsCount(Math.max(0, count - 1));
            challengeRepository.save(challenge);
        }
    }

    public UserSummary getCreatorInfo(String createdByUserId) {
        if (createdByUserId == null) {
            return null;
        }

        User creator = userRepository.findById(createdByUserId);

        if (creator == null) {
            return null;
        }

        return UserSummary.builder()
            .email(creator.getEmail())
            .name(creator.getName())
            .pictureUrl(creator.getPictureUrl())
            .socialMediaUrl(creator.getSocialMediaUrl())
            .build();
    }

    /**
     * Get only published hints (where publishedAt <= now)
     *
     * @param challenge The challenge
     * @return List of published hints
     */
    public List<Hint> getPublishedHints(Challenge challenge) {
        if (challenge.getHints() == null || challenge.getHints().isEmpty()) {
            return List.of();
        }

        Date now = new Date();
        return challenge.getHints().stream()
            .filter(hint -> hint.getPublishedAt() != null && !hint.getPublishedAt().after(now))
            .toList();
    }

    /**
     * Get the next unpublished hint date (where publishedAt > now)
     *
     * @param challenge The challenge
     * @return Date of next hint or null if none
     */
    public Date getNextHintDate(Challenge challenge) {
        if (challenge.getHints() == null || challenge.getHints().isEmpty()) {
            return null;
        }

        Date now = new Date();
        return challenge.getHints().stream()
            .filter(hint -> hint.getPublishedAt() != null && hint.getPublishedAt().after(now))
            .map(Hint::getPublishedAt)
            .min(Date::compareTo)
            .orElse(null);
    }

}