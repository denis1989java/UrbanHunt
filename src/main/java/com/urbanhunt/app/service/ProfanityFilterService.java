package com.urbanhunt.app.service;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class ProfanityFilterService {

    private final Set<Pattern> profanityPatterns;

    public ProfanityFilterService() {
        Set<String> allWords = new HashSet<>();

        // Load English profanity words
        allWords.addAll(loadWordsFromFile("profanity/en.txt"));

        // Load Spanish profanity words
        allWords.addAll(loadWordsFromFile("profanity/es.txt"));

        System.out.println("✅ Loaded " + allWords.size() + " profanity words");

        // Create patterns that match whole words (case insensitive)
        this.profanityPatterns = allWords.stream()
                .filter(word -> !word.trim().isEmpty())
                .map(word -> {
                    String trimmed = word.trim();
                    // Escape special regex characters but keep spaces as is for phrase matching
                    String pattern = "\\b" + Pattern.quote(trimmed) + "\\b";
                    return Pattern.compile(pattern, Pattern.CASE_INSENSITIVE);
                })
                .collect(Collectors.toSet());
    }

    /**
     * Load profanity words from a file in resources
     * @param filename Path to file in resources
     * @return Set of words
     */
    private Set<String> loadWordsFromFile(String filename) {
        Set<String> words = new HashSet<>();
        try {
            ClassPathResource resource = new ClassPathResource(filename);
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    String word = line.trim();
                    if (!word.isEmpty() && !word.startsWith("#")) {
                        words.add(word);
                    }
                }
            }
        } catch (IOException e) {
            System.err.println("⚠️ Failed to load profanity list from " + filename + ": " + e.getMessage());
        }
        return words;
    }

    /**
     * Check if text contains profanity
     * @param text Text to check
     * @return true if profanity found, false otherwise
     */
    public boolean containsProfanity(String text) {
        if (text == null || text.trim().isEmpty()) {
            return false;
        }

        String normalizedText = text.toLowerCase().trim();

        boolean found = profanityPatterns.stream()
                .anyMatch(pattern -> pattern.matcher(normalizedText).find());

        if (!found && System.getProperty("profanity.debug") != null) {
            System.out.println("DEBUG: Checking text: '" + normalizedText + "'");
            System.out.println("DEBUG: Total patterns: " + profanityPatterns.size());
        }

        return found;
    }

    /**
     * Validate text and throw exception if profanity found
     * @param text Text to validate
     * @param fieldName Name of field for error message
     * @throws IllegalArgumentException if profanity found
     */
    public void validateText(String text, String fieldName) {
        if (containsProfanity(text)) {
            throw new IllegalArgumentException(
                    String.format("Inappropriate content detected in %s", fieldName)
            );
        }
    }
}