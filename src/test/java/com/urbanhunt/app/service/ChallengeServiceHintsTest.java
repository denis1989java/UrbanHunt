package com.urbanhunt.app.service;

import com.urbanhunt.app.model.Challenge;
import com.urbanhunt.app.model.Hint;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ChallengeServiceHintsTest {

    private ChallengeService challengeService;

    @BeforeEach
    void setUp() {
        challengeService = new ChallengeService(null, null, null);
    }

    @Test
    void testGetPublishedHints_AllPublished() {
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.HOUR, -1); // 1 hour ago
        Date pastDate = cal.getTime();

        List<Hint> hints = new ArrayList<>();
        hints.add(Hint.builder().content("Hint 1").publishedAt(pastDate).build());
        hints.add(Hint.builder().content("Hint 2").publishedAt(pastDate).build());

        Challenge challenge = Challenge.builder().hints(hints).build();

        List<Hint> published = challengeService.getPublishedHints(challenge);
        assertEquals(2, published.size());
    }

    @Test
    void testGetPublishedHints_SomeUnpublished() {
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.HOUR, -1);
        Date pastDate = cal.getTime();

        cal = Calendar.getInstance();
        cal.add(Calendar.HOUR, 1); // 1 hour in future
        Date futureDate = cal.getTime();

        List<Hint> hints = new ArrayList<>();
        hints.add(Hint.builder().content("Published").publishedAt(pastDate).build());
        hints.add(Hint.builder().content("Not published").publishedAt(futureDate).build());

        Challenge challenge = Challenge.builder().hints(hints).build();

        List<Hint> published = challengeService.getPublishedHints(challenge);
        assertEquals(1, published.size());
        assertEquals("Published", published.get(0).getContent());
    }

    @Test
    void testGetPublishedHints_NonePublished() {
        Calendar cal = Calendar.getInstance();
        cal.add(Calendar.DAY_OF_MONTH, 1); // Tomorrow
        Date futureDate = cal.getTime();

        List<Hint> hints = new ArrayList<>();
        hints.add(Hint.builder().content("Future hint").publishedAt(futureDate).build());

        Challenge challenge = Challenge.builder().hints(hints).build();

        List<Hint> published = challengeService.getPublishedHints(challenge);
        assertEquals(0, published.size());
    }

    @Test
    void testGetPublishedHints_EmptyHints() {
        Challenge challenge = Challenge.builder().hints(new ArrayList<>()).build();
        List<Hint> published = challengeService.getPublishedHints(challenge);
        assertEquals(0, published.size());
    }

    @Test
    void testGetPublishedHints_NullHints() {
        Challenge challenge = Challenge.builder().hints(null).build();
        List<Hint> published = challengeService.getPublishedHints(challenge);
        assertEquals(0, published.size());
    }
}