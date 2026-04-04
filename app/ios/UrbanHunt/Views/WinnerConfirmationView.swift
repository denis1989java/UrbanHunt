//
//  WinnerConfirmationView.swift
//  UrbanHunt
//
//  View to display winner's confirmation details
//

import SwiftUI

struct WinnerConfirmationView: View {
    let confirmationId: String
    @Environment(\.dismiss) var dismiss

    @State private var confirmation: PrizeConfirmation?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    ErrorView(message: errorMessage) {
                        Task {
                            await loadConfirmation()
                        }
                    }
                } else if let confirmation = confirmation {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Check if winner left any reaction
                            if (confirmation.message == nil || confirmation.message!.isEmpty) &&
                               (confirmation.contentUrl == nil || confirmation.contentUrl!.isEmpty) {
                                // No reaction from winner
                                VStack(spacing: 16) {
                                    Image(systemName: "face.dashed")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)

                                    Text("no_winner_reaction".localized)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                // Winner left a reaction

                                // Message section
                                if let message = confirmation.message, !message.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("winner_message".localized)
                                            .font(.headline)
                                            .foregroundColor(.primary)

                                        Text(message)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(uiColor: .secondarySystemBackground))
                                            .cornerRadius(12)
                                    }
                                }

                                // Media section
                                if let contentUrl = confirmation.contentUrl, !contentUrl.isEmpty, let url = URL(string: contentUrl) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        CachedAsyncImage(
                                            url: url,
                                            content: { image in
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .cornerRadius(12)
                                            },
                                            placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(height: 300)
                                                    .cornerRadius(12)
                                                    .overlay(
                                                        ProgressView()
                                                    )
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    // Debug: No confirmation loaded
                    Text("No confirmation loaded - this should not happen")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("winner_confirmation".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                Task {
                    await loadConfirmation()
                }
            }
        }
    }

    private func loadConfirmation() async {
        print("🔍 WinnerConfirmationView: Loading confirmation with ID: \(confirmationId)")
        isLoading = true
        errorMessage = nil

        do {
            let loaded = try await APIService.shared.getPrizeConfirmationById(confirmationId)
            print("✅ WinnerConfirmationView: Loaded confirmation: \(loaded)")
            await MainActor.run {
                self.confirmation = loaded
                isLoading = false
                print("✅ WinnerConfirmationView: Set confirmation in state")
            }
        } catch {
            print("❌ WinnerConfirmationView: Error loading: \(error)")
            await MainActor.run {
                errorMessage = "Failed to load confirmation"
                isLoading = false
            }
        }
    }
}