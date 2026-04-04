//
//  ChallengeCard.swift
//  UrbanHunt
//
//  Challenge card component for home feed
//

import SwiftUI

struct ChallengeCard: View {
    let challenge: Challenge
    let viewModel: ChallengesViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showHints = false
    @State private var showComments = false
    @State private var showUserProfile = false
    @State private var showShareSheet = false
    @State private var showWinnerConfirmation = false

    var body: some View {
        cardContent
            .sheet(isPresented: $showHints) {
                HintsView(challenge: challenge)
            }
            .sheet(isPresented: $showComments) {
                CommentsView(
                    challengeId: challenge.id,
                    onCommentCountChanged: { newCount in
                        viewModel.updateCommentCount(for: challenge.id, newCount: newCount)
                    }
                )
                .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showUserProfile) {
                if let createdBy = challenge.createdBy {
                    UserProfileView(userId: createdBy)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheetView(
                    activityItems: [shareMessage]
                )
            }
            .sheet(isPresented: $showWinnerConfirmation) {
                if let confirmationId = challenge.confirmationId {
                    WinnerConfirmationView(confirmationId: confirmationId)
                }
            }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: Creator on left, Location and Share on right
            HStack(alignment: .top) {
                // Creator info (left)
                Button(action: {
                    if challenge.createdBy != nil {
                        showUserProfile = true
                    }
                }) {
                    HStack(spacing: 8) {
                        // Profile picture
                        if let creator = challenge.creator {
                            CachedAsyncImage(
                                url: URL(string: creator.pictureUrl ?? ""),
                                content: { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                },
                                placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        )
                                }
                            )
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())

                            Text(creator.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                )

                            Text("unknown_user".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(challenge.createdBy == nil)

                Spacer()

                // Location info and Share button (right)
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(challenge.country)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(challenge.cityName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    // Share button
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Challenge title
            Text(challenge.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)

            // Prize photo (if available)
            if let prizePhotoUrl = challenge.prizePhotoUrl {
                CachedAsyncImage(
                    url: URL(string: prizePhotoUrl),
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    },
                    placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .overlay(
                                ProgressView()
                            )
                    }
                )
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            // Bottom row: Status and metadata
            HStack {
                // Status badge
                Text(statusText)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(12)

                Spacer()

                // Date
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Next hint date (if available)
            if let nextHintDate = challenge.nextHintDate, challenge.status != .completed {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("next_hint".localized)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    Text(formatNextHintDate(nextHintDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // Action buttons
            VStack(spacing: 0) {
                // First row: Hints and Comments
                HStack(alignment: .center, spacing: 0) {
                    // Hints button
                    Button(action: {
                        showHints = true
                    }) {
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "lightbulb")
                                .font(.subheadline)
                            Text("hints".localized)
                                .font(.caption)
                            if let hints = challenge.hints, !hints.isEmpty {
                                Text("(\(hints.count))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, maxHeight: 40)

                    Divider()

                    // Comments button
                    Button(action: {
                        showComments = true
                    }) {
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.subheadline)
                            Text("comments".localized)
                                .font(.caption)
                            if let count = challenge.commentsCount, count > 0 {
                                Text("(\(count))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, maxHeight: 40)
                }

                // Second row: Confirmation button (only for completed challenges)
                if challenge.status == .completed, let confirmationId = challenge.confirmationId, !confirmationId.isEmpty {
                    Divider()
                        .padding(.vertical, 12)

                    Button(action: {
                        showWinnerConfirmation = true
                    }) {
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: "checkmark.seal")
                                .font(.subheadline)
                            Text("confirmation".localized)
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, maxHeight: 40)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var statusText: String {
        switch challenge.status {
        case .draft:
            return "draft".localized
        case .active:
            return "status_active".localized
        case .completed:
            return "status_completed".localized
        case .archived:
            return "status_archived".localized
        }
    }

    private var statusColor: Color {
        switch challenge.status {
        case .draft:
            return .orange
        case .active:
            return .green
        case .completed:
            return .blue
        case .archived:
            return .gray
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: challenge.createdAt, relativeTo: Date())
    }

    private func formatNextHintDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var shareMessage: String {
        let deepLink = "urbanhunt://challenge/\(challenge.id)"
        return """
        🎯 Check out this challenge: \(challenge.title)
        📍 \(challenge.cityName), \(challenge.country)

        \(deepLink)
        """
    }
}
