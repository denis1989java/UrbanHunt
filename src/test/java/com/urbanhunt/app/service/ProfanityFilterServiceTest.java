package com.urbanhunt.app.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class ProfanityFilterServiceTest {

    private ProfanityFilterService profanityFilterService;

    @BeforeEach
    void setUp() {
        profanityFilterService = new ProfanityFilterService();
    }

    @Test
    void testEnglishProfanity() {
        // Words from the actual LDNOOBW list
        assertTrue(profanityFilterService.containsProfanity("This is fucking bad"));
        assertTrue(profanityFilterService.containsProfanity("You are a bitch"));
        assertTrue(profanityFilterService.containsProfanity("SHIT happens"));
        assertTrue(profanityFilterService.containsProfanity("What a dick"));
        assertTrue(profanityFilterService.containsProfanity("This is bullshit"));
    }

    @Test
    void testSpanishProfanity() {
        // Words from the actual LDNOOBW Spanish list
        assertTrue(profanityFilterService.containsProfanity("Eres un cabrón"));
        assertTrue(profanityFilterService.containsProfanity("Qué coño"));
        assertTrue(profanityFilterService.containsProfanity("Es una puta"));
        assertTrue(profanityFilterService.containsProfanity("Mierda!"));
    }

    @Test
    void testCleanText() {
        assertFalse(profanityFilterService.containsProfanity("This is a nice challenge"));
        assertFalse(profanityFilterService.containsProfanity("Beautiful city"));
        assertFalse(profanityFilterService.containsProfanity("Amazing place to visit"));
        assertFalse(profanityFilterService.containsProfanity("Hello world"));
    }

    @Test
    void testMultiWordPhrases() {
        // Test phrases from the list
        assertTrue(profanityFilterService.containsProfanity("Have you seen 2 girls 1 cup"));
        assertTrue(profanityFilterService.containsProfanity("What an asshole"));
    }

    @Test
    void testValidateText() {
        // Should throw exception for profanity
        assertThrows(IllegalArgumentException.class, () -> {
            profanityFilterService.validateText("This is shit", "test field");
        });

        // Should not throw for clean text
        assertDoesNotThrow(() -> {
            profanityFilterService.validateText("This is nice", "test field");
        });
    }

    @Test
    void testEmptyAndNullText() {
        assertFalse(profanityFilterService.containsProfanity(null));
        assertFalse(profanityFilterService.containsProfanity(""));
        assertFalse(profanityFilterService.containsProfanity("   "));
    }

    @Test
    void testCaseInsensitive() {
        assertTrue(profanityFilterService.containsProfanity("FUCK"));
        assertTrue(profanityFilterService.containsProfanity("fuck"));
        assertTrue(profanityFilterService.containsProfanity("FuCk"));
        assertTrue(profanityFilterService.containsProfanity("CABRÓN"));
        assertTrue(profanityFilterService.containsProfanity("cabrón"));
    }
}