//
//  CompleteChallengeView.swift
//  UrbanHunt
//
//  Complete challenge screen for challenge creators
//

import SwiftUI

struct CompleteChallengeView: View {
    let challengeId: String
    let onCompleted: (() -> Void)?

    @Environment(\.dismiss) var dismiss
    @State private var winnerName: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Winner Name (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("winner_name".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("enter_winner_name".localized, text: $winnerName)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Complete Button
                    Button(action: {
                        Task {
                            await completeChallenge()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        } else {
                            Text("complete".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                    .background(isLoading ? Color.gray : Color.primary)
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .cornerRadius(8)
                    .disabled(isLoading)
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("complete_challenge".localized)
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

    private func completeChallenge() async {
        isLoading = true
        errorMessage = nil

        do {
            let completion = Completion(
                userId: "",  // Backend will set this
                userName: winnerName.isEmpty ? "Unknown" : winnerName,
                completedAt: Date(),
                proofPhotoUrl: nil
            )

            _ = try await APIService.shared.completeChallenge(
                challengeId: challengeId,
                completion: completion
            )

            await MainActor.run {
                // Post notification to refresh challenges
                NotificationCenter.default.post(name: NSNotification.Name("RefreshChallenges"), object: nil)
                dismiss()
                onCompleted?()
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}