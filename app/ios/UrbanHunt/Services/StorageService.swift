//
//  StorageService.swift
//  UrbanHunt
//
//  Service for Cloud Storage operations
//

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    static let shared = StorageService()

    private let storage = Storage.storage()
    private let bucketName = Config.storageBucketName

    private init() {}

    func uploadProfilePicture(userId: String, image: UIImage) async throws -> String {
        print("🔄 StorageService: Starting upload...")

        // Resize image to max 512x512 for profile pictures
        let resizedImage = image.resized(to: CGSize(width: 512, height: 512))

        // Compress with lower quality for smaller file size
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.6) else {
            print("❌ StorageService: Failed to convert image to JPEG")
            throw StorageError.invalidImage
        }

        print("📦 Image data size: \(imageData.count) bytes (\(imageData.count / 1024) KB)")

        // Use fixed filename to overwrite previous profile picture
        let fileName = "profiles/\(userId)/profile.jpg"
        print("📁 Upload path: \(fileName)")

        // Use default bucket reference
        let storageRef = storage.reference().child(fileName)
        print("🔗 Storage ref: \(storageRef.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        // Set cache control to allow caching but revalidate
        metadata.cacheControl = "public, max-age=3600"

        print("⬆️ Uploading...")
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        print("✅ Upload complete")

        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await storageRef.downloadURL()

        // Add timestamp to URL to bust cache when image changes
        // Use & since Firebase URL already has query parameters
        let urlWithTimestamp = downloadURL.absoluteString + "&t=\(Int(Date().timeIntervalSince1970))"
        print("✅ Download URL: \(urlWithTimestamp)")
        return urlWithTimestamp
    }

    func uploadHintMedia(challengeId: String, hintIndex: Int, image: UIImage) async throws -> String {
        print("🔄 StorageService: Starting hint media upload...")

        // Resize image to max 1024x1024 for hint images
        let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))

        // Compress with medium quality
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ StorageService: Failed to convert image to JPEG")
            throw StorageError.invalidImage
        }

        print("📦 Image data size: \(imageData.count) bytes (\(imageData.count / 1024) KB)")

        // Use fixed filename based on hint index to overwrite previous hint media
        let fileName = "hints/\(challengeId)/hint_\(hintIndex).jpg"
        print("📁 Upload path: \(fileName)")

        let storageRef = storage.reference().child(fileName)
        print("🔗 Storage ref: \(storageRef.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        // Set cache control to allow caching but revalidate
        metadata.cacheControl = "public, max-age=3600"

        print("⬆️ Uploading...")
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        print("✅ Upload complete")

        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await storageRef.downloadURL()

        // Add timestamp to URL to bust cache when image changes
        let urlWithTimestamp = downloadURL.absoluteString + "&t=\(Int(Date().timeIntervalSince1970))"
        print("✅ Download URL: \(urlWithTimestamp)")
        return urlWithTimestamp
    }

    func uploadPrizePhoto(challengeId: String, image: UIImage) async throws -> String {
        print("🔄 StorageService: Starting prize photo upload...")

        // Resize image to max 1024x1024 for prize photos
        let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))

        // Compress with medium quality
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ StorageService: Failed to convert image to JPEG")
            throw StorageError.invalidImage
        }

        print("📦 Image data size: \(imageData.count) bytes (\(imageData.count / 1024) KB)")

        // Use fixed filename to overwrite previous prize photo
        let fileName = "prizes/\(challengeId)/prize.jpg"
        print("📁 Upload path: \(fileName)")

        let storageRef = storage.reference().child(fileName)
        print("🔗 Storage ref: \(storageRef.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        // Set cache control to allow caching but revalidate
        metadata.cacheControl = "public, max-age=3600"

        print("⬆️ Uploading...")
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        print("✅ Upload complete")

        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await storageRef.downloadURL()

        // Add timestamp to URL to bust cache when image changes
        let urlWithTimestamp = downloadURL.absoluteString + "&t=\(Int(Date().timeIntervalSince1970))"
        print("✅ Download URL: \(urlWithTimestamp)")
        return urlWithTimestamp
    }

    // Upload prize confirmation content (photo or video)
    func uploadPrizeConfirmationContent(confirmationId: String, data: Data) async throws -> String {
        print("📤 Starting prize confirmation content upload...")

        // Detect file extension based on content type
        var fileExtension = "jpg"
        var contentType = "image/jpeg"

        if data.count > 4 {
            let bytes = [UInt8](data.prefix(4))
            if bytes == [0xFF, 0xD8, 0xFF] {
                fileExtension = "jpg"
                contentType = "image/jpeg"
            } else if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
                fileExtension = "png"
                contentType = "image/png"
            } else {
                fileExtension = "mp4"
                contentType = "video/mp4"
            }
        }

        // Use fixed filename based on confirmationId to overwrite previous content
        let fileName = "prize-confirmations/\(confirmationId)/content.\(fileExtension)"
        print("📁 Upload path: \(fileName)")

        let storageRef = storage.reference().child(fileName)
        print("🔗 Storage ref: \(storageRef.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = contentType
        // Set cache control to allow caching but revalidate
        metadata.cacheControl = "public, max-age=3600"

        print("⬆️ Uploading...")
        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        print("✅ Upload complete")

        // Get download URL
        print("🔗 Getting download URL...")
        let downloadURL = try await storageRef.downloadURL()

        // Add timestamp to URL to bust cache when content changes
        let urlWithTimestamp = downloadURL.absoluteString + "&t=\(Int(Date().timeIntervalSince1970))"
        print("✅ Download URL: \(urlWithTimestamp)")
        return urlWithTimestamp
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Use smaller ratio to fit within target size
        let scaleFactor = min(widthRatio, heightRatio)

        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )

        let renderer = UIGraphicsImageRenderer(size: scaledSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: scaledSize))
        }
    }
}

enum StorageError: Error {
    case invalidImage
    case uploadFailed

    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .uploadFailed:
            return "Failed to upload image"
        }
    }
}