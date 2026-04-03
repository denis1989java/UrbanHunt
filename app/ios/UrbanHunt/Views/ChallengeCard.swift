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
            HStack(spacing: 0) {
                // Hints button
                Button(action: {
                    showHints = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb")
                            .font(.subheadline)
                        Text("hints".localized)
                            .font(.subheadline)
                        if let hints = challenge.hints, !hints.isEmpty {
                            Text("(\(hints.count))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                Divider()
                    .frame(height: 20)

                // Comments button
                Button(action: {
                    showComments = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.subheadline)
                        Text("comments".localized)
                            .font(.subheadline)
                        if let count = challenge.commentsCount, count > 0 {
                            Text("(\(count))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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