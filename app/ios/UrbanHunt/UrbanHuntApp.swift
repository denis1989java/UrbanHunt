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
    @State private var confirmationId: String?

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
                        if let confirmationId = confirmationId {
                            ConfirmPrizeView(confirmationId: confirmationId)
                                .onAppear {
                                    print("🎯 Sheet: Opening ConfirmPrizeView with confirmationId: \(confirmationId)")
                                }
                        } else {
                            Text("Error: No confirmation ID")
                                .onAppear {
                                    print("❌ Sheet: confirmationId is nil!")
                                }
                        }
                    }
                    .onChange(of: showConfirmPrize) { newValue in
                        print("🔔 showConfirmPrize changed to: \(newValue)")
                        print("🔔 confirmationId is: \(confirmationId ?? "nil")")
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
        // Handle urbanhunt://confirm/{confirmationId} - confirm prize
        else if url.scheme == "urbanhunt", url.host == "confirm" {
            if let confirmationId = url.pathComponents.last {
                print("🔗 Opening confirm prize with confirmationId: \(confirmationId)")
                self.confirmationId = confirmationId

                print("🔗 Setting showConfirmPrize to: true")
                showConfirmPrize = true
                print("🔗 showConfirmPrize is now: \(showConfirmPrize)")
                print("🔗 confirmationId is now: \(self.confirmationId ?? "nil")")
            } else {
                print("❌ Could not extract confirmationId from path")
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