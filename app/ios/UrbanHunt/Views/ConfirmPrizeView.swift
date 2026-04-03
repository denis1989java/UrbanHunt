//
//  ConfirmPrizeView.swift
//  UrbanHunt
//
//  View for confirming prize finding
//

import SwiftUI
import PhotosUI

struct ConfirmPrizeView: View {
    let confirmationId: String
    @Environment(\.dismiss) var dismiss
    @State private var confirmation: PrizeConfirmation?
    @State private var isLoadingConfirmation = true
    @State private var message: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    init(confirmationId: String) {
        self.confirmationId = confirmationId
        print("🎯 ConfirmPrizeView: INIT called with confirmationId: \(confirmationId)")
    }

    var body: some View {
        NavigationView {
            Group {
                if isLoadingConfirmation {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .padding(.top, 8)
                    }
                    .onAppear {
                        print("🎨 ConfirmPrizeView body: showing loading state")
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else if let confirmation = confirmation {
                    if confirmation.status == .done {
                        // Already confirmed
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("prize_already_confirmed".localized)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        confirmationForm
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        Text("confirmation_not_found".localized)
                            .font(.headline)
                    }
                    .padding()
                }
            }
            .navigationTitle("confirm_prize".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("cancel".localized)
                    }
                }
            }
            .task {
                print("📍 ConfirmPrizeView: .task called")
                await loadConfirmation()
            }
        }
    }

    private func loadConfirmation() async {
        print("🔄 ConfirmPrizeView: Loading confirmation with ID: \(confirmationId)")
        isLoadingConfirmation = true
        errorMessage = nil

        do {
            confirmation = try await APIService.shared.getPrizeConfirmationById(confirmationId)
            print("✅ ConfirmPrizeView: Successfully loaded confirmation: \(confirmation?.id ?? "nil")")
            print("✅ ConfirmPrizeView: Status: \(confirmation?.status.rawValue ?? "nil")")
        } catch {
            print("❌ ConfirmPrizeView: Failed to load confirmation: \(error)")
            errorMessage = "failed_to_load".localized + ": \(error.localizedDescription)"
        }

        isLoadingConfirmation = false
        print("🔄 ConfirmPrizeView: Loading completed. isLoadingConfirmation=\(isLoadingConfirmation), confirmation=\(confirmation != nil), errorMessage=\(errorMessage ?? "nil")")
    }

    private var confirmationForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Message input
                VStack(alignment: .leading, spacing: 8) {
                    Text("optional_message".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if message.isEmpty {
                                    Text("optional_message".localized)
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.top, 16)
                                        .padding(.leading, 12)
                                }
                            },
                            alignment: .topLeading
                        )
                }

                // Photo/Video picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("add_photo_or_video".localized)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                        HStack {
                            if let imageData = selectedImageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Text("tap_to_change".localized)
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .frame(width: 60, height: 60)
                                Text("select_media".localized)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(height: 80)
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                // Submit button
                Button(action: {
                    Task {
                        await submitConfirmation()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("confirm_prize_found".localized)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(isSubmitting ? Color.blue.opacity(0.5) : Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isSubmitting)
            }
            .padding()
        }
    }

    private func submitConfirmation() async {
        print("📤 ConfirmPrizeView: Submitting confirmation")
        isSubmitting = true
        errorMessage = nil

        // Upload content first if selected
        var contentUrl: String? = nil
        if let imageData = selectedImageData {
            print("📤 Uploading selected media...")
            do {
                contentUrl = try await StorageService.shared.uploadPrizeConfirmationContent(imageData)
                print("✅ Media uploaded successfully: \(contentUrl ?? "nil")")
            } catch {
                print("❌ Upload failed: \(error)")
                errorMessage = "upload_failed".localized + ": \(error.localizedDescription)"
                isSubmitting = false
                return
            }
        }

        // Submit confirmation
        do {
            _ = try await APIService.shared.confirmPrizeById(
                confirmationId: confirmationId,
                message: message.isEmpty ? nil : message,
                contentUrl: contentUrl
            )
            print("✅ Prize confirmation submitted successfully")

            // Post notification to refresh challenges
            await MainActor.run {
                NotificationCenter.default.post(name: NSNotification.Name("RefreshChallenges"), object: nil)
            }

            // Close the view
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ Submit failed: \(error)")
            errorMessage = "submit_failed".localized + ": \(error.localizedDescription)"
        }

        isSubmitting = false
    }
}

#Preview {
    ConfirmPrizeView(confirmationId: "test-id")
}