//
//  SocialMediaHelper.swift
//  UrbanHunt
//
//  Helper for formatting social media URLs
//

import Foundation

struct SocialMediaHelper {

    /// Extract a beautiful display text from social media URL
    /// - Parameter url: Full social media URL
    /// - Returns: Formatted display text (e.g., "@username" for Instagram)
    static func beautifyURL(_ url: String) -> String {
        // Check for Instagram URL patterns
        if url.contains("instagram.com") {
            return extractInstagramUsername(from: url)
        }

        // Check for Twitter/X URL patterns
        if url.contains("twitter.com") || url.contains("x.com") {
            return extractTwitterUsername(from: url)
        }

        // Check for TikTok URL patterns
        if url.contains("tiktok.com") {
            return extractTikTokUsername(from: url)
        }

        // Check for Facebook URL patterns
        if url.contains("facebook.com") || url.contains("fb.com") {
            return extractFacebookUsername(from: url)
        }

        // For other URLs, try to extract domain
        return extractDomain(from: url)
    }

    /// Detect social media platform from URL
    /// - Parameter url: Social media URL
    /// - Returns: Platform icon name
    static func platformIcon(for url: String) -> String? {
        if url.contains("instagram.com") {
            return "camera.fill"
        }
        if url.contains("twitter.com") || url.contains("x.com") {
            return "bubble.left.and.bubble.right.fill"
        }
        if url.contains("tiktok.com") {
            return "music.note"
        }
        if url.contains("facebook.com") || url.contains("fb.com") {
            return "person.2.fill"
        }
        return "link"
    }

    // MARK: - Private helpers

    private static func extractInstagramUsername(from url: String) -> String {
        // Pattern: https://www.instagram.com/username or https://instagram.com/username
        // Extract username between instagram.com/ and next / or ?

        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.components(separatedBy: "/").filter({ !$0.isEmpty }).first else {
            return url
        }

        return "@\(path)"
    }

    private static func extractTwitterUsername(from url: String) -> String {
        // Pattern: https://twitter.com/username or https://x.com/username

        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.components(separatedBy: "/").filter({ !$0.isEmpty }).first else {
            return url
        }

        return "@\(path)"
    }

    private static func extractTikTokUsername(from url: String) -> String {
        // Pattern: https://www.tiktok.com/@username

        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.components(separatedBy: "/").filter({ !$0.isEmpty }).first else {
            return url
        }

        // TikTok usernames already start with @
        return path.hasPrefix("@") ? path : "@\(path)"
    }

    private static func extractFacebookUsername(from url: String) -> String {
        // Pattern: https://www.facebook.com/username

        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.components(separatedBy: "/").filter({ !$0.isEmpty }).first else {
            return url
        }

        return path
    }

    private static func extractDomain(from url: String) -> String {
        // Extract domain for other URLs
        guard let urlComponents = URLComponents(string: url),
              let host = urlComponents.host else {
            return url
        }

        // Remove www. prefix if present
        return host.replacingOccurrences(of: "www.", with: "")
    }
}