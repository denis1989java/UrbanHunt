//
//  ErrorView.swift
//  UrbanHunt
//
//  Reusable error view component with consistent styling
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.8))

            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                        Text("Retry")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

// Inline error message component (for form errors)
struct InlineErrorView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(.red)

            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 40) {
        ErrorView(
            message: "Failed to load challenges. Please try again.",
            retryAction: { print("Retry tapped") }
        )

        InlineErrorView(message: "Title is required")
            .padding()
    }
}