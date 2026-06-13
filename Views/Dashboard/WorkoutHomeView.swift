import SwiftUI

// Trakkit Workout tab (Figma: https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=736-2474 )

struct WorkoutHomeView: View {
    @StateObject private var viewModel = DashboardViewModel2()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var categoryStore: CategoryConfigStore

    @State private var showCreateWorkout = false
    @State private var showQuickStarterSession = false
    @State private var selectedUserWorkout: Workout?
    @State private var showPlanGenerator = false
    @State private var showExerciseLibrary = false
    @State private var selectedWorkout: Workout?
    @State private var templateWorkouts: [Workout] = []
    @State private var exploreFilter: WorkoutHomeExploreFilter = .build

    private let primaryOrange = Color(hex: "#FF9500")
    private let screenBg = AppConstants.TrakkitHome.background

    var isPremium: Bool {
        authViewModel.currentUser?.subscriptionStatus == .premium
    }

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Workout")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#6B6B6B"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)

                    UpcomingSessionCardView(
                        session: viewModel.upcomingSession(for: authViewModel.currentUser),
                        isFirstTimeUser: viewModel.isFirstTimeHomeEmptyState,
                        userName: authViewModel.currentUser?.name ?? "User",
                        onFilledCardTap: {
                            if let w = viewModel.userWorkouts.first, w.userId != nil {
                                selectedUserWorkout = w
                                HapticFeedback.impact()
                            }
                        },
                        onCreateTap: {
                            showCreateWorkout = true
                            HapticFeedback.impact()
                        },
                        onStartFirstWorkoutTap: {
                            showQuickStarterSession = true
                            HapticFeedback.impact()
                        }
                    )
                    .padding(.horizontal, 20)

                    MyWorkoutSectionView(
                        actions: viewModel.workoutActions,
                        userWorkouts: viewModel.userWorkouts,
                        isFirstTimeUser: viewModel.isFirstTimeHomeEmptyState,
                        onActionTap: { handleWorkoutAction($0) },
                        onWorkoutTap: { handleUserWorkoutTap($0) }
                    )

                    WorkoutHomeCategoriesRow(
                        onSelect: { filter in
                            exploreFilter = filter
                            HapticFeedback.impact()
                        }
                    )
                    .padding(.horizontal, 20)

                    WorkoutHomeExploreSection(
                        filter: $exploreFilter,
                        workouts: filteredExploreWorkouts,
                        isPremium: isPremium,
                        primaryOrange: primaryOrange,
                        onStart: { w in
                            selectedWorkout = w
                            HapticFeedback.impact()
                        }
                    )
                    .padding(.horizontal, 20)

                    Spacer(minLength: 120)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            AnalyticsService.shared.trackScreenView("WorkoutHome", screenClass: "WorkoutHomeView")
            Task {
                await viewModel.fetchDashboardData(userId: authViewModel.currentUser?.id)
                await loadTemplateWorkouts()
            }
        }
        .task { await categoryStore.reload() }
        .onChange(of: showCreateWorkout) { _, isPresented in
            if !isPresented {
                Task { await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutCreated"))) { _ in
            Task { await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutDeleted"))) { _ in
            Task { await viewModel.fetchUserWorkouts(userId: authViewModel.currentUser?.id) }
        }
        .fullScreenCover(isPresented: $showCreateWorkout) {
            CreateWorkoutView()
                .environmentObject(authViewModel)
                .environmentObject(categoryStore)
        }
        .fullScreenCover(isPresented: $showQuickStarterSession) {
            WorkoutSessionStartView(
                workout: Workout.quickStarterTemplate(),
                userId: authViewModel.currentUser?.id ?? "",
                presentation: .quickStarterFirstWorkout
            )
            .environmentObject(authViewModel)
        }
        .fullScreenCover(item: $selectedWorkout) { workout in
            if workout.isPremium && !isPremium {
                PaywallView()
                    .environmentObject(authViewModel)
                    .onAppear { selectedWorkout = nil }
            } else {
                VideoPlayerView(workout: workout)
            }
        }
        .fullScreenCover(item: $selectedUserWorkout) { workout in
            WorkoutSessionStartView(
                workout: workout,
                userId: authViewModel.currentUser?.id ?? ""
            )
            .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showPlanGenerator) {
            NavigationStack {
                PlanGeneratorView()
                    .environmentObject(authViewModel)
            }
        }
        .sheet(isPresented: $showExerciseLibrary) {
            NavigationStack {
                ExerciseLibraryView(exercises: viewModel.exercises)
            }
        }
    }

    private var filteredExploreWorkouts: [Workout] {
        let list = templateWorkouts
        let filtered: [Workout] = {
            switch exploreFilter {
            case .build:
                return list.filter { [.strength, .hiit].contains($0.category) }
            case .recovery:
                return list.filter { [.yoga, .flexibility].contains($0.category) }
            case .maintain:
                return list.filter { $0.category == .cardio }
            }
        }()
        if filtered.isEmpty { return Array(list.prefix(6)) }
        return Array(filtered.prefix(6))
    }

    private func loadTemplateWorkouts() async {
        do {
            let w = try await WorkoutService.shared.fetchTemplateWorkouts()
            await MainActor.run {
                templateWorkouts = w.isEmpty ? SampleData.workouts : w
            }
        } catch {
            await MainActor.run { templateWorkouts = SampleData.workouts }
        }
    }

    private func handleUserWorkoutTap(_ workout: Workout) {
        if workout.userId != nil {
            selectedUserWorkout = workout
            HapticFeedback.impact()
        } else {
            handleWorkoutTap(workout)
        }
    }

    private func handleWorkoutTap(_ workout: Workout) {
        selectedWorkout = workout
        HapticFeedback.impact()
    }

    private func handleWorkoutAction(_ type: WorkoutActionType) {
        switch type {
        case .newWorkout:
            showCreateWorkout = true
            HapticFeedback.impact()
        case .customPlan:
            showPlanGenerator = true
            HapticFeedback.impact()
        case .myExercises:
            showExerciseLibrary = true
            HapticFeedback.impact()
        }
    }
}

// MARK: - Explore filter

enum WorkoutHomeExploreFilter: String, CaseIterable {
    case build = "Build"
    case recovery = "Recovery"
    case maintain = "Maintain"
}

// MARK: - Categories (horizontal)

private enum WorkoutHomeCategoryCardMetrics {
    /// Sized for full-bleed admin card artwork (portrait-ish assets).
    static let width: CGFloat = 148
    static let height: CGFloat = 168
    static let cornerRadius: CGFloat = 18
}

private struct WorkoutHomeCategoriesRow: View {
    let onSelect: (WorkoutHomeExploreFilter) -> Void
    @EnvironmentObject private var categoryStore: CategoryConfigStore

    private var useRemoteCategories: Bool {
        categoryStore.isLoaded
            && !categoryStore.categories(for: .workoutHome).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.TrakkitHome.heading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if useRemoteCategories {
                        ForEach(categoryStore.categories(for: .workoutHome)) { cat in
                            let gradient = cat.gradientColors(
                                for: .workoutHome,
                                fallback: ["#E8E8E8", "#D0D0D0"]
                            ).map { Color(hex: $0) }
                            let filter = cat.exploreFilterEnum() ?? .build
                            categoryCard(
                                title: cat.label(for: .workoutHome, fallback: cat.id),
                                gradient: gradient,
                                imageURL: cat.normalizedImageURL,
                                bundledAsset: bundledAssetName(for: cat.id),
                                systemFallback: cat.sfSymbolFallback ?? "figure.run"
                            ) { onSelect(filter) }
                        }
                    } else {
                        ForEach(CategoryConfigFallback.workoutHome, id: \.title) { item in
                            categoryCard(
                                title: item.title,
                                gradient: item.gradient.map { Color(hex: $0) },
                                imageURL: categoryStore.imageURL(forCategoryId: fallbackCategoryId(for: item.title)),
                                bundledAsset: item.image,
                                systemFallback: item.sfSymbol
                            ) { onSelect(item.filter) }
                        }
                    }
                }
            }
        }
        .task { await categoryStore.reload() }
    }

    private func fallbackCategoryId(for title: String) -> String {
        switch title {
        case "yog": return "yoga"
        default: return title
        }
    }

    private func bundledAssetName(for categoryId: String) -> String? {
        switch categoryId {
        case "yoga": return "yoga"
        case "strength": return "dumble"
        default: return nil
        }
    }

    @ViewBuilder
    private func categoryCard(
        title: String,
        gradient: [Color],
        imageURL: URL?,
        bundledAsset: String?,
        systemFallback: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                if let imageURL {
                    CategoryRemoteImage(url: imageURL, contentMode: .fit) {
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        categorySymbol(bundledAsset: bundledAsset, systemFallback: systemFallback)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text(title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#1A1A1A").opacity(0.85))
                            .padding(12)
                    }
                } else {
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    Group {
                        if let bundledAsset, !bundledAsset.isEmpty {
                            Image(bundledAsset)
                                .resizable()
                                .scaledToFit()
                                .padding(12)
                        } else {
                            categorySymbol(bundledAsset: nil, systemFallback: systemFallback)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)

                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#1A1A1A").opacity(0.85))
                        .padding(12)
                }
            }
            .frame(
                width: WorkoutHomeCategoryCardMetrics.width,
                height: WorkoutHomeCategoryCardMetrics.height
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: WorkoutHomeCategoryCardMetrics.cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: WorkoutHomeCategoryCardMetrics.cornerRadius,
                    style: .continuous
                )
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func categorySymbol(bundledAsset: String?, systemFallback: String) -> some View {
        if let bundledAsset, !bundledAsset.isEmpty {
            Image(bundledAsset)
                .resizable()
                .scaledToFit()
                .padding(12)
        } else {
            Image(systemName: systemFallback)
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.35))
        }
    }
}

// MARK: - Explore list

private struct WorkoutHomeExploreSection: View {
    @Binding var filter: WorkoutHomeExploreFilter
    let workouts: [Workout]
    let isPremium: Bool
    let primaryOrange: Color
    let onStart: (Workout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Explore")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.TrakkitHome.heading)

            HStack(spacing: 8) {
                ForEach(WorkoutHomeExploreFilter.allCases, id: \.self) { mode in
                    let on = filter == mode
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { filter = mode }
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(on ? .white : AppConstants.TrakkitHome.heading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(on ? Color(hex: "#1A1A1A") : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: "#E5E5E5"), lineWidth: on ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 12) {
                ForEach(workouts) { w in
                    WorkoutHomeExploreRow(
                        workout: w,
                        isPremium: isPremium,
                        primaryOrange: primaryOrange,
                        onStart: { onStart(w) }
                    )
                }
            }
        }
    }
}

private struct WorkoutHomeExploreRow: View {
    let workout: Workout
    let isPremium: Bool
    let primaryOrange: Color
    let onStart: () -> Void

    private var showLock: Bool { workout.isPremium && !isPremium }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                thumbnail
                    .frame(height: 150)
                    .clipped()
                if showLock {
                    Color.black.opacity(0.25)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(workout.difficulty.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.22))
                    .clipShape(Capsule())
                    .padding(10)
            }
            .frame(maxWidth: .infinity)

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                        .lineLimit(1)
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(workout.duration) min")
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(workout.caloriesBurned) kcal")
                        }
                    }
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                }
                Spacer(minLength: 4)
                Button(action: onStart) {
                    Text("Start")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(primaryOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: primaryOrange.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = workout.thumbnailURL, !url.isEmpty, let u = URL(string: url) {
            AsyncImage(url: u) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholderGradient
                }
            }
        } else {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(hex: "#4A4A4A"), Color(hex: "#2C2C2C")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    NavigationView {
        WorkoutHomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(CategoryConfigStore.shared)
    }
}
