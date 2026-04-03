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
    @State private var isUploading = false
    @State private var uploadedContentUrl: String?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            Group {
                if isLoadingConfirmation {
                    ProgressView()
                        .scaleEffect(1.5)
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
                await loadConfirmation()
            }
            .alert("success".localized, isPresented: $showSuccess) {
                Button("ok".localized) {
                    dismiss()
                }
            } message: {
                Text("prize_confirmed_successfully".localized)
            }
        }
    }

    private func loadConfirmation() async {
        isLoadingConfirmation = true
        errorMessage = nil

        do {
            confirmation = try await APIService.shared.getPrizeConfirmationById(confirmationId)
        } catch {
            errorMessage = "failed_to_load".localized + ": \(error.localizedDescription)"
        }

        isLoadingConfirmation = false
    }

    private var confirmationForm: some View {
        Form {
            Section(header: Text("prize_found".localized)) {
                // Message input
                TextEditor(text: $message)
                    .frame(minHeight: 100)
                    .overlay(
                        Group {
                            if message.isEmpty {
                                Text("optional_message".localized)
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        },
                        alignment: .topLeading
                    )
            }

            Section(header: Text("add_photo_or_video".localized)) {
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundColor(.blue)
                        Text("select_media".localized)
                            .foregroundColor(.primary)
                        Spacer()
                        if isUploading {
                            ProgressView()
                        }
                    }
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                            await uploadContent(data)
                        }
                    }
                }

                // Preview selected image
                if let imageData = selectedImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                }

                if let url = uploadedContentUrl {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("media_uploaded".localized)
                            .foregroundColor(.green)
                    }
                }
            }

            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button(action: {
                    Task {
                        await submitConfirmation()
                    }
                }) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("confirm_prize_found".localized)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(isSubmitting || isUploading)
            }
        }
    }

    private func uploadContent(_ data: Data) async {
        isUploading = true
        errorMessage = nil

        do {
            let url = try await StorageService.shared.uploadPrizeConfirmationContent(data)
            uploadedContentUrl = url
        } catch {
            errorMessage = "upload_failed".localized + ": \(error.localizedDescription)"
        }

        isUploading = false
    }

    private func submitConfirmation() async {
        isSubmitting = true
        errorMessage = nil

        do {
            _ = try await APIService.shared.confirmPrizeById(
                confirmationId: confirmationId,
                message: message.isEmpty ? nil : message,
                contentUrl: uploadedContentUrl
            )
            showSuccess = true
        } catch {
            errorMessage = "submit_failed".localized + ": \(error.localizedDescription)"
        }

        isSubmitting = false
    }
}

#Preview {
    ConfirmPrizeView(confirmationId: "test-id")
}