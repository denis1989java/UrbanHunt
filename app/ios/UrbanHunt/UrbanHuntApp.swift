import SwiftUI
import Firebase

@main
struct UrbanHuntApp: App {

    init() {
        // Configure Firebase
        FirebaseApp.configure()

        // Initialize theme
        _ = ThemeManager.shared
        _ = LocalizationManager.shared
    }

    @StateObject private var authViewModel = AuthViewModel()
    @State private var versionCheckCompleted = false
    @State private var updateRequired = false
    @State private var updateMessage = ""
    @State private var latestVersion: String?
    @State private var deepLinkChallengeId: String?
    @State private var showDeepLinkedChallenge = false
    @State private var showConfirmPrize = false

    var body: some Scene {
        WindowGroup {
            if updateRequired {
                UpdateRequiredView(message: updateMessage, latestVersion: latestVersion)
            } else if !versionCheckCompleted {
                // Show loading while checking version
                ProgressView()
                    .scaleEffect(1.5)
                    .task {
                        await checkAppVersion()
                    }
            } else if authViewModel.isAuthenticated {
                MainView()
                    .environmentObject(authViewModel)
                    .sheet(isPresented: $showDeepLinkedChallenge) {
                        if let challengeId = deepLinkChallengeId {
                            ChallengeDetailView(challengeId: challengeId)
                                .environmentObject(authViewModel)
                        }
                    }
                    .sheet(isPresented: $showConfirmPrize) {
                        if let challengeId = deepLinkChallengeId {
                            ConfirmPrizeView(challengeId: challengeId)
                        }
                    }
                    .onChange(of: showDeepLinkedChallenge) { newValue in
                        print("🔔 showDeepLinkedChallenge changed to: \(newValue)")
                        print("🔔 deepLinkChallengeId is: \(deepLinkChallengeId ?? "nil")")
                    }
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .onOpenURL { url in
                        // Store deep link for after login
                        if url.scheme == "urbanhunt", url.host == "challenge" {
                            deepLinkChallengeId = url.pathComponents.last
                        }
                    }
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url)")
        print("🔗 URL scheme: \(url.scheme ?? "nil")")
        print("🔗 URL host: \(url.host ?? "nil")")
        print("🔗 URL pathComponents: \(url.pathComponents)")

        // Handle urbanhunt://challenge/{id} - view challenge
        if url.scheme == "urbanhunt", url.host == "challenge" {
            if let challengeId = url.pathComponents.last, !url.pathComponents.contains("confirm") {
                print("🔗 Opening challenge: \(challengeId)")
                print("🔗 Setting deepLinkChallengeId to: \(challengeId)")
                deepLinkChallengeId = challengeId
                print("🔗 Setting showDeepLinkedChallenge to: true")
                showDeepLinkedChallenge = true
                print("🔗 showDeepLinkedChallenge is now: \(showDeepLinkedChallenge)")
            } else {
                print("❌ Could not extract challengeId from pathComponents")
            }
        }
        // Handle urbanhunt://challenge/{id}/confirm - confirm prize
        else if url.scheme == "urbanhunt", url.host == "challenge", url.pathComponents.contains("confirm") {
            // Extract challengeId from path like /challenge/{id}/confirm
            if url.pathComponents.count >= 3 {
                let challengeId = url.pathComponents[2] // Index: 0="", 1="challenge", 2="{id}"
                print("🔗 Opening confirm prize for challenge: \(challengeId)")
                deepLinkChallengeId = challengeId
                showConfirmPrize = true
            } else {
                print("❌ Could not extract challengeId from confirm path")
            }
        }
        else {
            print("❌ URL scheme or host doesn't match. scheme=\(url.scheme ?? "nil"), host=\(url.host ?? "nil")")
        }
    }

    private func checkAppVersion() async {
        do {
            let response = try await APIService.shared.checkVersion()

            print("✅ Version check: supported=\(response.supported), updateRequired=\(response.updateRequired)")

            await MainActor.run {
                if response.updateRequired {
                    updateRequired = true
                    updateMessage = response.updateMessage ?? "please_update_app".localized
                    latestVersion = response.latestVersion
                } else {
                    versionCheckCompleted = true
                }
            }
        } catch {
            print("⚠️ Version check failed: \(error), allowing app to continue")
            // On error, allow app to continue (don't block users)
            await MainActor.run {
                versionCheckCompleted = true
            }
        }
    }
}