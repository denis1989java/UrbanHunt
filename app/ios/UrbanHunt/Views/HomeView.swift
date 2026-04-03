//
//  HomeView.swift
//  UrbanHunt
//
//  Home screen with user profile and challenges
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var showSideMenu = false
    @State private var showFiltersSheet = false

    var body: some View {
        LocalizedView {
            content
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshChallenges"))) { _ in
            Task {
                await viewModel.refreshChallenges()
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

    private var content: some View {
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    // Top bar with burger menu and filters button
                    HStack(spacing: 12) {
                        // Burger menu button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSideMenu = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.primary)
                                .frame(width: 40, height: 40)
                        }

                        Spacer()

                        // App title
                        Text("Urban Hunt")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Spacer()

                        // Filters button
                        Button(action: {
                            showFiltersSheet = true
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)

                                // Badge indicator when filters are active
                                if viewModel.selectedCountry != nil || viewModel.selectedCity != nil || viewModel.selectedStatus != nil {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 2, y: 2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(uiColor: .systemBackground))

                    Divider()

                    // Selected filters display
                    if viewModel.selectedCountry != nil || viewModel.selectedCity != nil || viewModel.selectedStatus != nil {
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text("active_filters".localized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .fontWeight(.medium)

                                Spacer()

                                // Clear filters button
                                Button(action: {
                                    Task {
                                        await viewModel.clearFilters()
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                        Text("clear".localized)
                                            .font(.caption)
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }

                            FlowLayout(spacing: 8) {
                                // Selected country
                                if let country = viewModel.selectedCountry {
                                    HStack(spacing: 6) {
                                        Image(systemName: "globe")
                                            .font(.caption)
                                        Text(country)
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }

                                // Selected city
                                if let city = viewModel.selectedCity {
                                    HStack(spacing: 6) {
                                        Image(systemName: "building.2")
                                            .font(.caption)
                                        Text(city)
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }

                                // Selected status
                                if let status = viewModel.selectedStatus {
                                    HStack(spacing: 6) {
                                        Image(systemName: "flag")
                                            .font(.caption)
                                        Text(statusText(status))
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .systemBackground))

                        Divider()
                    }

                    // Challenges list
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 16) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                            Button("Retry") {
                                Task {
                                    await viewModel.loadChallenges()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.challenges.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("no_challenges_yet".localized)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.challenges) { challenge in
                                    ChallengeCard(challenge: challenge, viewModel: viewModel)
                                        .environmentObject(authViewModel)
                                        .onAppear {
                                            // Load more when reaching last item
                                            if challenge.id == viewModel.challenges.last?.id {
                                                Task {
                                                    await viewModel.loadMoreChallenges()
                                                }
                                            }
                                        }
                                }

                                // Loading indicator at bottom
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding()
                        }
                        .background(Color(uiColor: .systemBackground))
                        .refreshable {
                            await viewModel.refreshChallenges()
                        }
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .task {
                    await viewModel.loadChallenges()
                }
                .sheet(isPresented: $showFiltersSheet) {
                    FiltersView(viewModel: viewModel)
                }
            }
            .disabled(showSideMenu)

            // Side menu overlay
            SideMenuView(isShowing: $showSideMenu)
                .environmentObject(authViewModel)
        }
    }
}

// FlowLayout for wrapping filters
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// Filters View - All filters in one screen
struct FiltersView: View {
    @ObservedObject var viewModel: ChallengesViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                // Country Filter Section
                Section(header: Text("filter_by_country".localized)) {
                    // "All Countries" option
                    Button(action: {
                        Task {
                            await viewModel.filterByCountry(nil)
                        }
                    }) {
                        HStack {
                            Text("all_countries".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedCountry == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // Individual countries
                    ForEach(viewModel.availableCountries.sorted(), id: \.self) { country in
                        Button(action: {
                            Task {
                                await viewModel.filterByCountry(country)
                            }
                        }) {
                            HStack {
                                Text(country)
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.selectedCountry == country {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                // City Filter Section
                Section(header: Text("filter_by_city".localized)) {
                    // "All Cities" option
                    Button(action: {
                        Task {
                            await viewModel.filterByCity(nil)
                        }
                    }) {
                        HStack {
                            Text("all_cities".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedCity == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .disabled(viewModel.selectedCountry == nil)

                    // Individual cities
                    ForEach(viewModel.availableCities.sorted(), id: \.self) { city in
                        Button(action: {
                            Task {
                                await viewModel.filterByCity(city)
                            }
                        }) {
                            HStack {
                                Text(city)
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.selectedCity == city {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .disabled(viewModel.selectedCountry == nil)
                }

                // Status Filter Section
                Section(header: Text("filter_by_status".localized)) {
                    // "All Statuses" option
                    Button(action: {
                        Task {
                            await viewModel.filterByStatus(nil)
                        }
                    }) {
                        HStack {
                            Text("all_statuses".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedStatus == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // Active
                    Button(action: {
                        Task {
                            await viewModel.filterByStatus(.active)
                        }
                    }) {
                        HStack {
                            Text("status_active".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedStatus == .active {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }

                    // Completed
                    Button(action: {
                        Task {
                            await viewModel.filterByStatus(.completed)
                        }
                    }) {
                        HStack {
                            Text("status_completed".localized)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.selectedStatus == .completed {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                // Clear Filters Section
                if viewModel.selectedCountry != nil || viewModel.selectedCity != nil || viewModel.selectedStatus != nil {
                    Section {
                        Button(action: {
                            Task {
                                await viewModel.clearFilters()
                            }
                        }) {
                            HStack {
                                Spacer()
                                Text("clear_all_filters".localized)
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("filters".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("done".localized)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}