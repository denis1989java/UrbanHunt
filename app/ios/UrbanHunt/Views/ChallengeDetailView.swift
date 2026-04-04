//
//  ChallengeDetailView.swift
//  UrbanHunt
//
//  Detailed view of a single challenge
//

import SwiftUI

struct ChallengeDetailView: View {
    let challengeId: String
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var challenge: Challenge?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showUserProfile = false
    @State private var showWinnerConfirmation = false
    @Environment(\.dismiss) var dismiss

    init(challengeId: String) {
        self.challengeId = challengeId
        print("🎯 ChallengeDetailView: INIT called with challengeId: \(challengeId)")
    }

    var body: some View {
        LocalizedView {
            content
        }
        .task {
            print("📍 ChallengeDetailView: .task called")
            await loadChallenge()
        }
        .onAppear {
            print("📍 ChallengeDetailView: .onAppear called for challengeId: \(challengeId)")
        }
    }

    private var content: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading challenge...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage) {
                        Task {
                            await loadChallenge()
                        }
                    }
                } else if let challenge = challenge {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Top section: Creator on left, Location on right
                            HStack(alignment: .top) {
                                // Creator info
                                Button(action: {
                                    if challenge.createdBy != nil {
                                        showUserProfile = true
                                    }
                                }) {
                                    HStack(spacing: 8) {
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
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())

                                            Text(creator.name)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                        } else {
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Image(systemName: "person.fill")
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

                                // Location on right
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(challenge.country)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text(challenge.cityName)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)

                            // Title
                            Text(challenge.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            // Status badge
                            HStack {
                                Text(statusText(challenge.status))
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(statusColor(challenge.status).opacity(0.1))
                                    .foregroundColor(statusColor(challenge.status))
                                    .cornerRadius(12)

                                Spacer()
                            }
                            .padding(.horizontal)

                            // Prize photo
                            if let prizePhotoUrl = challenge.prizePhotoUrl {
                                CachedAsyncImage(
                                    url: URL(string: prizePhotoUrl),
                                    content: { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                    },
                                    placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.1))
                                            .overlay(
                                                ProgressView()
                                            )
                                    }
                                )
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }

                            // Confirmation section for completed challenges
                            if challenge.status == .completed, let confirmationId = challenge.confirmationId {
                                Button(action: {
                                    showWinnerConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                        Text("confirmation".localized)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            // Hints section
                            if let hints = challenge.hints, !hints.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.orange)
                                        Text("hints".localized)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                        Text("\(hints.count)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)

                                    ForEach(Array(hints.enumerated()), id: \.offset) { index, hint in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Hint \(index + 1)")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)

                                                Spacer()

                                                if let publishedAt = hint.publishedAt {
                                                    Text(formatHintDate(publishedAt))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }

                                            Text(hint.content)
                                                .font(.body)
                                                .foregroundColor(.primary)

                                            if let link = hint.link, !link.isEmpty {
                                                CachedAsyncImage(
                                                    url: URL(string: link),
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
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 200)
                                                .clipped()
                                                .cornerRadius(8)
                                            }
                                        }
                                        .padding()
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                    }
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "lightbulb.slash")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("no_hints_added".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }
                        }
                    }
                    .sheet(isPresented: $showUserProfile) {
                        if let createdBy = challenge.createdBy {
                            UserProfileView(userId: createdBy)
                        }
                    }
                    .sheet(isPresented: $showWinnerConfirmation) {
                        if let confirmationId = challenge.confirmationId {
                            WinnerConfirmationView(confirmationId: confirmationId)
                        }
                    }
                } else {
                    Text("challenge_not_found".localized)
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    private func loadChallenge() async {
        print("🔄 ChallengeDetailView: Loading challenge with ID: \(challengeId)")
        isLoading = true
        errorMessage = nil

        do {
            // Load specific challenge by ID
            let loadedChallenge = try await APIService.shared.getChallenge(id: challengeId)
            print("✅ ChallengeDetailView: Successfully loaded challenge: \(loadedChallenge.title)")
            await MainActor.run {
                self.challenge = loadedChallenge
                self.isLoading = false
            }
        } catch {
            print("❌ ChallengeDetailView: Failed to load challenge: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func statusText(_ status: Challenge.ChallengeStatus) -> String {
        switch status {
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

    private func statusColor(_ status: Challenge.ChallengeStatus) -> Color {
        switch status {
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

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatNextHintDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatHintDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    ChallengeDetailView(challengeId: "test-id")
        .environmentObject(AuthViewModel())
}