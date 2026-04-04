//
//  EditChallengeView.swift
//  UrbanHunt
//
//  Edit challenge screen
//

import SwiftUI
import PhotosUI

struct EditChallengeView: View {
    let challenge: Challenge
    let onChallengeUpdated: ((Challenge) -> Void)?
    let onChallengeDeleted: (() -> Void)?

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var currentStatus: Challenge.ChallengeStatus
    @State private var hasCompletion: Bool
    @State private var title: String = ""
    @State private var country: String = ""
    @State private var cityName: String = ""
    @State private var location: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(challenge: Challenge, onChallengeUpdated: ((Challenge) -> Void)?, onChallengeDeleted: (() -> Void)?) {
        self.challenge = challenge
        self.onChallengeUpdated = onChallengeUpdated
        self.onChallengeDeleted = onChallengeDeleted
        _currentStatus = State(initialValue: challenge.status)
        _hasCompletion = State(initialValue: challenge.completion != nil)
    }
    @State private var showDeleteConfirmation = false
    @State private var hasUnsavedChanges = false
    @State private var showNoHintsAlert = false

    @State private var countries: [Country] = []
    @State private var selectedCountry: Country?
    @State private var availableCities: [String] = []
    @State private var showCountryPicker = false
    @State private var showCityPicker = false
    @State private var showAddHint = false
    @State private var existingHints: [HintWithId] = []
    @State private var prizePhotoItem: PhotosPickerItem?
    @State private var prizePhoto: UIImage?
    @State private var prizePhotoUrl: String?
    @State private var editMode: EditMode = .inactive
    @State private var editingHintId: UUID?
    @State private var hintsModified = false
    @State private var showConfirmationLink = false
    @State private var confirmationDeepLink: String?
    @State private var showCompleteChallenge = false
    @State private var prizeConfirmationId: String?
    @State private var showQRCode = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            formFields
                            actionButtons
                        }
                        .padding()
                    }
                }

                errorMessageView
            }
            .navigationTitle("edit_challenge".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }

                if currentStatus == .draft {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            if existingHints.isEmpty {
                                showNoHintsAlert = true
                            } else {
                                Task {
                                    await activateChallenge()
                                }
                            }
                        }) {
                            Text("activate".localized)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoading)
                    }
                }

                if currentStatus == .active && !hasCompletion {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            loadPrizeConfirmationId()
                        }) {
                            Text("complete".localized)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerSheet(
                    countries: countries,
                    selectedCountry: $selectedCountry,
                    onSelect: { country in
                        let previousCountry = self.country
                        self.country = country.name
                        self.availableCities = country.cities
                        self.selectedCountry = country

                        // Reset city if country changed
                        if previousCountry != country.name {
                            self.cityName = ""
                        }

                        checkForUnsavedChanges()
                        showCountryPicker = false
                    }
                )
            }
            .sheet(isPresented: $showCityPicker) {
                CityPickerSheet(
                    cities: availableCities,
                    selectedCity: $cityName,
                    onSelect: { city in
                        self.cityName = city
                        checkForUnsavedChanges()
                        showCityPicker = false
                    }
                )
            }
            .sheet(isPresented: $showAddHint) {
                AddHintView(
                    challengeId: challenge.id,
                    currentHintCount: existingHints.count,
                    onHintAdded: { hint in
                        existingHints.append(HintWithId(hint: hint))
                        hintsModified = true
                        checkForUnsavedChanges()
                        showAddHint = false
                    }
                )
            }
            .sheet(isPresented: Binding(
                get: { editingHintId != nil },
                set: { if !$0 { editingHintId = nil } }
            )) {
                if let hintId = editingHintId,
                   let hintWithId = existingHints.first(where: { $0.id == hintId }),
                   let index = existingHints.firstIndex(where: { $0.id == hintId }) {
                    EditExistingHintSheet(
                        hint: hintWithId.hint,
                        onSave: { content, publishDate in
                            existingHints[index] = HintWithId(
                                id: hintWithId.id,
                                hint: Hint(
                                    content: content,
                                    link: hintWithId.hint.link,
                                    publishedAt: publishDate
                                )
                            )
                            hintsModified = true
                            checkForUnsavedChanges()
                            editingHintId = nil
                        },
                        onDelete: {
                            existingHints.remove(at: index)
                            hintsModified = true
                            checkForUnsavedChanges()
                            editingHintId = nil
                        },
                        onCancel: {
                            editingHintId = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showCompleteChallenge) {
                if let confirmationId = prizeConfirmationId {
                    ConfirmPrizeView(confirmationId: confirmationId)
                }
            }
            .sheet(isPresented: $showQRCode) {
                if let deepLink = confirmationDeepLink {
                    QRCodeView(deepLink: deepLink, challengeTitle: challenge.title)
                }
            }
            .modifier(AlertsModifier(
                showDeleteConfirmation: $showDeleteConfirmation,
                showConfirmationLink: $showConfirmationLink,
                showNoHintsAlert: $showNoHintsAlert,
                confirmationDeepLink: $confirmationDeepLink,
                onDelete: { Task { await deleteChallenge() } },
                onDismiss: { dismiss() },
                onViewQRCode: { showQRCode = true }
            ))
            .onAppear {
                loadInitialData()
                loadCountries()
                // Reload challenge data to get latest hints
                Task {
                    await refreshChallenge()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshChallenges"))) { _ in
                Task {
                    await refreshChallenge()
                }
            }
        }
    }

    private var formFields: some View {
        VStack(spacing: 24) {
            statusDisplay
            countryPicker
            cityPicker
            locationField
            titleField
            prizePhotoSection
            hintsSection
        }
    }

    private var countryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("country".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: {
                if currentStatus != .completed {
                    showCountryPicker = true
                }
            }) {
                HStack {
                    Text(country.isEmpty ? "select_country".localized : country)
                        .foregroundColor(country.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(currentStatus == .completed)
            .opacity(currentStatus == .completed ? 0.5 : 1.0)
        }
    }

    private var cityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("city".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            Button(action: {
                if !availableCities.isEmpty && currentStatus != .completed {
                    showCityPicker = true
                }
            }) {
                HStack {
                    Text(cityName.isEmpty ? "select_city".localized : cityName)
                        .foregroundColor(cityName.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(availableCities.isEmpty || currentStatus == .completed)
            .opacity((availableCities.isEmpty || currentStatus == .completed) ? 0.5 : 1.0)
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("challenge_name".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            TextField("enter_challenge_title".localized, text: $title)
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: title) { _, newValue in
                    let maxLength = 100
                    if newValue.count > maxLength {
                        let truncated = newValue.prefix(maxLength)
                        title = String(truncated)
                    }
                    checkForUnsavedChanges()
                }
                .disabled(currentStatus == .completed)
                .opacity(currentStatus == .completed ? 0.5 : 1.0)
        }
    }

    private var locationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("location".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            TextField("enter_location".localized, text: $location)
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: location) { _, newValue in
                    let maxLength = 200
                    if newValue.count > maxLength {
                        let truncated = newValue.prefix(maxLength)
                        location = String(truncated)
                    }
                    checkForUnsavedChanges()
                }
                .disabled(currentStatus == .completed)
                .opacity(currentStatus == .completed ? 0.5 : 1.0)

            Text("location_note".localized)
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.8))
        }
    }

    private var statusDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("status".localized)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(statusText)
                .font(.body)
                .foregroundColor(statusColor)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(8)
        }
    }

    private var prizePhotoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("prize_photo".localized)
                .font(.subheadline)
                .foregroundColor(.gray)

            PhotosPicker(selection: $prizePhotoItem, matching: .images) {
                HStack {
                    if let image = prizePhoto {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text("photo_selected".localized)
                                .foregroundColor(.primary)
                            Text("tap_to_change".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else if let prizePhotoUrl = prizePhotoUrl, !prizePhotoUrl.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: prizePhotoUrl),
                            content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            },
                            placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            }
                        )

                        VStack(alignment: .leading) {
                            Text("photo_selected".localized)
                                .foregroundColor(.primary)
                            Text("tap_to_change".localized)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                        Text("select_prize_photo".localized)
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
            .disabled(currentStatus == .completed)
            .opacity(currentStatus == .completed ? 0.5 : 1.0)
            .onChange(of: prizePhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        prizePhoto = image
                        checkForUnsavedChanges()
                    }
                }
            }
        }
    }

    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("hints".localized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
                if currentStatus != .completed {
                    Button(action: {
                        showAddHint = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text("add_hint".localized)
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }

            if existingHints.isEmpty {
                Text("no_hints_added".localized)
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
            } else {
                List {
                    ForEach(existingHints) { hintWithId in
                        let index = existingHints.firstIndex(where: { $0.id == hintWithId.id }) ?? 0
                        HStack(alignment: .top, spacing: 12) {
                            if let link = hintWithId.hint.link, !link.isEmpty, let url = URL(string: link) {
                                CachedAsyncImage(
                                    url: url,
                                    content: { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    },
                                    placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                            .cornerRadius(6)
                                            .overlay(
                                                ProgressView()
                                            )
                                    }
                                )
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Hint \(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    if let publishedAt = hintWithId.hint.publishedAt {
                                        Text(formatDate(publishedAt))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if !hintWithId.hint.content.isEmpty {
                                    Text(hintWithId.hint.content)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editMode == .inactive && currentStatus != .completed {
                                editingHintId = hintWithId.id
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.5) {
                            if currentStatus != .completed {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                withAnimation {
                                    editMode = .active
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            if currentStatus != .completed {
                                Button(role: .destructive) {
                                    if let index = existingHints.firstIndex(where: { $0.id == hintWithId.id }) {
                                        existingHints.remove(at: index)
                                        hintsModified = true
                                        checkForUnsavedChanges()
                                    }
                                } label: {
                                    Label("delete".localized, systemImage: "trash")
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    .onMove { from, to in
                        if currentStatus != .completed {
                            existingHints.move(fromOffsets: from, toOffset: to)
                            hintsModified = true
                            checkForUnsavedChanges()
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: CGFloat(existingHints.count) * 85)
                .scrollDisabled(true)
                .environment(\.editMode, $editMode)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            if currentStatus != .completed {
                saveButton
            }

            // Show QR Code button for DRAFT and ACTIVE challenges
            if (currentStatus == .draft || currentStatus == .active),
               let confirmationId = challenge.confirmationId,
               !confirmationId.isEmpty {
                viewQRCodeButton
            }

            if challenge.status != .archived {
                deleteButton
            }
        }
    }

    private var saveButton: some View {
        Button(action: {
            Task {
                await saveChanges()
            }
        }) {
            Text("save_changes".localized)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasUnsavedChanges && isFormValid ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(isLoading || !hasUnsavedChanges || !isFormValid)
    }

    private var viewQRCodeButton: some View {
        Button(action: {
            if let confirmationId = challenge.confirmationId {
                confirmationDeepLink = "urbanhunt://confirm/\(confirmationId)"
                showQRCode = true
            }
        }) {
            Text("view_qr_code".localized)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
        }
        .disabled(isLoading)
    }

    private var deleteButton: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            Text("delete_challenge".localized)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = errorMessage {
            InlineErrorView(message: errorMessage)
                .padding(.horizontal)
        }
    }

    private var statusText: String {
        switch currentStatus {
        case .draft:
            return "draft".localized
        case .active:
            return "active".localized
        case .completed:
            return "completed".localized
        case .archived:
            return "archived".localized
        }
    }

    private var statusColor: Color {
        switch currentStatus {
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

    private var isFormValid: Bool {
        let basicFieldsValid = !title.trimmingCharacters(in: .whitespaces).isEmpty &&
            !country.trimmingCharacters(in: .whitespaces).isEmpty &&
            !cityName.trimmingCharacters(in: .whitespaces).isEmpty

        // If challenge is active, must have at least 1 hint
        if challenge.status == .active {
            return basicFieldsValid && !existingHints.isEmpty
        }

        return basicFieldsValid
    }

    private func loadInitialData() {
        title = challenge.title
        country = challenge.country
        cityName = challenge.cityName
        location = challenge.location ?? ""
        existingHints = (challenge.hints ?? []).map { HintWithId(hint: $0) }
        prizePhotoUrl = challenge.prizePhotoUrl
    }

    private func loadPrizeConfirmationId() {
        Task {
            do {
                let confirmation = try await APIService.shared.getPrizeConfirmation(challengeId: challenge.id)
                await MainActor.run {
                    prizeConfirmationId = confirmation.id
                    showCompleteChallenge = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func refreshChallenge() async {
        do {
            let updatedChallenge = try await APIService.shared.getChallenge(id: challenge.id)
            await MainActor.run {
                // Update hints locally without triggering full update
                existingHints = (updatedChallenge.hints ?? []).map { HintWithId(hint: $0) }
                hasCompletion = updatedChallenge.completion != nil
                currentStatus = updatedChallenge.status  // Update status as well
                onChallengeUpdated?(updatedChallenge)
            }
        } catch {
            // Ignore errors on refresh
        }
    }

    private func loadCountries() {
        Task {
            do {
                countries = try await APIService.shared.getCountries()
                selectedCountry = countries.first { $0.name == country }
                if let selectedCountry = selectedCountry {
                    availableCities = selectedCountry.cities
                }
            } catch {
                print("❌ Error loading countries: \(error)")
            }
        }
    }

    private func checkForUnsavedChanges() {
        let titleChanged = title != challenge.title
        let countryChanged = country != challenge.country
        let cityChanged = cityName != challenge.cityName
        let prizePhotoChanged = prizePhoto != nil
        hasUnsavedChanges = titleChanged || countryChanged || cityChanged || prizePhotoChanged || hintsModified
    }

    private func saveChanges() async {
        isLoading = true
        errorMessage = nil

        do {
            var finalPrizePhotoUrl = challenge.prizePhotoUrl

            // Upload new prize photo if selected
            if let prizePhoto = prizePhoto {
                print("⬆️ Uploading prize photo...")
                finalPrizePhotoUrl = try await StorageService.shared.uploadPrizePhoto(
                    challengeId: challenge.id,
                    image: prizePhoto
                )
                print("✅ Prize photo uploaded: \(finalPrizePhotoUrl ?? "")")
            }

            let updatedChallenge = try await APIService.shared.updateChallenge(
                challengeId: challenge.id,
                title: title.trimmingCharacters(in: .whitespaces),
                country: country.trimmingCharacters(in: .whitespaces),
                cityName: cityName.trimmingCharacters(in: .whitespaces),
                location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location.trimmingCharacters(in: .whitespaces),
                prizePhotoUrl: finalPrizePhotoUrl
            )

            await MainActor.run {
                isLoading = false
                hasUnsavedChanges = false
                prizePhotoUrl = finalPrizePhotoUrl
                self.prizePhoto = nil
                onChallengeUpdated?(updatedChallenge)
            }
        } catch {
            print("❌ Error saving changes: \(error)")
            await MainActor.run {
                if let apiError = error as? APIError {
                    errorMessage = apiError.localizedDescription
                } else {
                    errorMessage = "Failed to save changes"
                }
                isLoading = false
            }
        }
    }

    private func activateChallenge() async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await APIService.shared.updateChallengeStatus(
                challengeId: challenge.id,
                status: .active
            )

            await MainActor.run {
                isLoading = false
                currentStatus = .active  // Update local status
                onChallengeUpdated?(result.challenge)
                // No alerts - just update silently
            }
        } catch {
            print("❌ Error activating challenge: \(error)")
            await MainActor.run {
                errorMessage = "Failed to activate challenge"
                isLoading = false
            }
        }
    }

    private func deleteChallenge() async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await APIService.shared.updateChallengeStatus(
                challengeId: challenge.id,
                status: .archived
            )

            await MainActor.run {
                isLoading = false
                onChallengeDeleted?()
                dismiss()
            }
        } catch {
            print("❌ Error deleting challenge: \(error)")
            await MainActor.run {
                errorMessage = "Failed to delete challenge"
                isLoading = false
            }
        }
    }
}

struct AlertsModifier: ViewModifier {
    @Binding var showDeleteConfirmation: Bool
    @Binding var showConfirmationLink: Bool
    @Binding var showNoHintsAlert: Bool
    @Binding var confirmationDeepLink: String?
    let onDelete: () -> Void
    let onDismiss: () -> Void
    let onViewQRCode: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("delete_challenge".localized, isPresented: $showDeleteConfirmation) {
                Button("cancel".localized, role: .cancel) { }
                Button("delete".localized, role: .destructive, action: onDelete)
            } message: {
                Text("delete_challenge_message".localized)
            }
            .alert("activate_challenge".localized, isPresented: $showNoHintsAlert) {
                Button("ok".localized, role: .cancel) { }
            } message: {
                Text("cannot_activate_without_hints".localized)
            }
            .alert("prize_confirmation_link".localized, isPresented: $showConfirmationLink) {
                Button("view_qr_code".localized) {
                    onViewQRCode()
                }
                Button("copy_link".localized) {
                    if let link = confirmationDeepLink {
                        UIPasteboard.general.string = link
                    }
                }
                Button("done".localized, role: .cancel) {
                    onDismiss()
                }
            } message: {
                if let link = confirmationDeepLink {
                    Text("share_this_link_message".localized + ":\n\n\(link)")
                }
            }
    }
}

struct HintWithId: Identifiable {
    let id: UUID
    let hint: Hint

    init(hint: Hint) {
        self.id = UUID()
        self.hint = hint
    }

    init(id: UUID, hint: Hint) {
        self.id = id
        self.hint = hint
    }
}

struct EditExistingHintSheet: View {
    let hint: Hint
    let onSave: (String, Date) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @State private var content: String
    @State private var publishDate: Date
    @State private var publishImmediately: Bool
    @State private var showDatePicker = false

    init(hint: Hint, onSave: @escaping (String, Date) -> Void, onDelete: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.hint = hint
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _content = State(initialValue: hint.content)
        _publishDate = State(initialValue: hint.publishedAt ?? Date())
        _publishImmediately = State(initialValue: abs((hint.publishedAt ?? Date()).timeIntervalSinceNow) < 60)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hint Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("hint_text".localized)
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("enter_hint".localized, text: $content, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Show media if exists
                    if let link = hint.link, !link.isEmpty, let url = URL(string: link) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("media_optional".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            CachedAsyncImage(
                                url: url,
                                content: { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(8)
                                },
                                placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)
                                        .cornerRadius(8)
                                        .overlay(
                                            ProgressView()
                                        )
                                }
                            )
                        }
                    }

                    // Publish Immediately Toggle
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("publish_immediately".localized, isOn: $publishImmediately)
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Publish Date Picker (only if not immediate)
                    if !publishImmediately {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("publish_date".localized)
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Button(action: {
                                showDatePicker = true
                            }) {
                                HStack {
                                    Text(formatDate(publishDate))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            Button(action: onCancel) {
                                Text("cancel".localized)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }

                            Button(action: {
                                let finalDate = publishImmediately ? Date() : publishDate
                                onSave(content, finalDate)
                            }) {
                                Text("save".localized)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(canSave ? Color.primary : Color.gray.opacity(0.4))
                                    .foregroundColor(Color(uiColor: .systemBackground))
                                    .cornerRadius(8)
                            }
                            .disabled(!canSave)
                        }

                        Button(action: onDelete) {
                            Text("delete_hint".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("edit_hint".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                NavigationView {
                    VStack {
                        DatePicker(
                            "select_date_and_time".localized,
                            selection: $publishDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding()

                        Spacer()

                        Button(action: {
                            showDatePicker = false
                        }) {
                            Text("done".localized)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.primary)
                                .foregroundColor(Color(uiColor: .systemBackground))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                    .navigationTitle("select_date".localized)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showDatePicker = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

