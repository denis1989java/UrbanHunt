//
//  QRCodeView.swift
//  UrbanHunt
//
//  QR Code view for prize confirmation
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let deepLink: String
    let challengeTitle: String
    @Environment(\.dismiss) var dismiss

    @State private var qrImage: UIImage?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions
                    Text("qr_code_instructions".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top)

                    // QR Code
                    if let qrImage = qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(radius: 4)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 280, height: 280)
                            .cornerRadius(16)
                            .overlay(
                                ProgressView()
                            )
                    }

                    // Share button
                    Button(action: shareQRCode) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("share_qr".localized)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(qrImage == nil)
                }
                .padding(.vertical)
            }
            .navigationTitle("qr_code_title".localized)
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
                generateQRCode()
            }
        }
    }

    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        // Create QR code data
        let data = Data(deepLink.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        // Generate QR code
        if let outputImage = filter.outputImage {
            // Scale up the QR code for better quality
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = UIImage(cgImage: cgImage)
            }
        }
    }

    private func shareQRCode() {
        guard let qrImage = qrImage else { return }

        // Create a shareable image with title
        let renderer = ImageRenderer(content: shareableView())

        guard let uiImage = renderer.uiImage else { return }

        // Share using SwiftUI's shareSheet
        let activityController = UIActivityViewController(
            activityItems: [uiImage],
            applicationActivities: nil
        )

        // Present the activity controller
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return
        }

        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        // For iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(
                x: topController.view.bounds.midX,
                y: topController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        topController.present(activityController, animated: true)
    }

    @ViewBuilder
    private func shareableView() -> some View {
        VStack(spacing: 20) {
            Text("qr_code_share_message".localized)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)

            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
            }
        }
        .frame(width: 400, height: 450)
        .background(Color.white)
    }
}