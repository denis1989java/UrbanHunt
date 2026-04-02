package com.urbanhunt.app.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class VersionServiceTest {

    private VersionService versionService;

    @BeforeEach
    void setUp() {
        versionService = new VersionService(null); // Repository not needed for version comparison tests
    }

    @Test
    void testVersionComparison_Equal() {
        assertTrue(versionService.isVersionSupported("1.0.0", "1.0.0"));
        assertTrue(versionService.isVersionSupported("2.5.3", "2.5.3"));
    }

    @Test
    void testVersionComparison_CurrentIsNewer() {
        assertTrue(versionService.isVersionSupported("1.2.0", "1.0.0"));
        assertTrue(versionService.isVersionSupported("2.0.0", "1.9.9"));
        assertTrue(versionService.isVersionSupported("1.0.1", "1.0.0"));
    }

    @Test
    void testVersionComparison_CurrentIsOlder() {
        assertFalse(versionService.isVersionSupported("1.0.0", "1.2.0"));
        assertFalse(versionService.isVersionSupported("1.9.9", "2.0.0"));
        assertFalse(versionService.isVersionSupported("1.0.0", "1.0.1"));
    }

    @Test
    void testVersionComparison_DifferentLength() {
        assertTrue(versionService.isVersionSupported("1.2", "1.0.0"));
        assertTrue(versionService.isVersionSupported("1.0.0", "1.0"));
        assertFalse(versionService.isVersionSupported("1.0", "1.0.1"));
    }

    @Test
    void testVersionComparison_NullVersions() {
        // Null versions should allow (graceful fallback)
        assertTrue(versionService.isVersionSupported(null, "1.0.0"));
        assertTrue(versionService.isVersionSupported("1.0.0", null));
        assertTrue(versionService.isVersionSupported(null, null));
    }
}