import SwiftUI

// Figma: https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=182-1041

enum WorkoutSessionStartPresentation {
    /// User-created workout: add exercises, violet “AI OPTIMIZED” card at bottom.
    case standard
    /// First-time canned “Quick Workout”: Today’s workout, Aura banner, fixed list design.
    case quickStarterFirstWorkout
}

/// Pre-session setup screen for user-created workouts.
/// Keeps users out of legacy exercise-log flow and routes to in-session logging.
struct WorkoutSessionStartView: View {
    let workout: Workout
    let userId: String
    var presentation: WorkoutSessionStartPresentation = .standard

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    @State private var showSessionLog = false
    @State private var showExerciseSelection = false
    @State private var selectedTechniqueExercise: Exercise?
    @State private var loadError: String?
    @StateObject private var createWorkoutViewModel = CreateWorkoutViewModel()

    private let screenBg = Color(hex: "#F5F5F7")
    private let primaryOrange = Color(hex: "#FF9500")
    /// Figma: rich violet gradient for AI block.
    private let aiPurpleA = Color(hex: "#6B2DE8")
    private let aiPurpleB = Color(hex: "#A855E8")
    private let easyBadgeGreen = Color(hex: "#2BBF62")
    private let easyBadgeBg = Color(hex: "#B7F7BE")
    private let cardBorder = Color(hex: "#E5E5EA")

    private var isQuickStarter: Bool {
        presentation == .quickStarterFirstWorkout
    }

    private var navTitle: String {
        isQuickStarter ? "Quick Workout" : workout.title
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            screenBg.ignoresSafeArea()

            if let err = loadError {
                LoadFailureFallbackView(
                    message: err,
                    onRetry: { Task { await loadExercises() } },
                    onGoBack: { dismiss() }
                )
            } else {
                ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerBar
                    if isQuickStarter {
                        quickStartHero
                        auraSaysCard
                        exerciseRowsCard
                        techniqueGuideSection
                    } else {
                        setLogSection
                        addExerciseButton
                        techniqueGuideSection
                        if !exercises.isEmpty { aiOptimizedCard }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }

            startSessionButton
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadExercises()
        }
        .fullScreenCover(isPresented: $showExerciseSelection) {
            ExerciseSelectionView(
                workoutName: workout.title,
                workoutDescription: workout.description,
                viewModel: createWorkoutViewModel,
                existingWorkout: workout,
                onDismiss: nil
            )
            .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showSessionLog) {
            WorkoutSessionLogView(
                workout: workout,
                exercises: exercises,
                userId: userId,
                onFinished: { _ in
                    showSessionLog = false
                }
            )
            .environmentObject(authViewModel)
        }
        .sheet(item: $selectedTechniqueExercise) { exercise in
            ExerciseDetailView(exercise: exercise, workout: workout)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutUpdated"))) { _ in
            Task { await loadExercises() }
        }
    }

    private var headerBar: some View {
        ZStack {
            Text(navTitle)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
            HStack(alignment: .center) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#3A3A3C"))
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 4)
    }

    private var quickStartHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Workout")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            HStack(alignment: .center, spacing: 10) {
                Text("\(workout.duration) mins")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#3A3A3C"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#E8E8ED"))
                    .clipShape(Capsule())

                HStack(spacing: 8) {
                    Circle()
                        .fill(primaryOrange)
                        .frame(width: 6, height: 6)
                    Text("BEGINNER FRIENDLY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                        .tracking(0.3)
                }
            }
        }
    }

    private var auraSaysCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppConstants.TrakkitAI.iconBox)
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Aura says:")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitAI.title)
                Text("This is back starter workout. Focus on form over weights.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppConstants.TrakkitAI.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    AppConstants.TrakkitAI.rowGradientTop,
                    AppConstants.TrakkitAI.cardFill
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppConstants.TrakkitAI.cardBorder.opacity(0.85), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// Exercise list without “Set Log” heading (quick starter).
    private var exerciseRowsCard: some View {
        exerciseRowsContent
    }

    @ViewBuilder
    private var exerciseRowsContent: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else if exercises.isEmpty {
            Text(isQuickStarter ? "We couldn’t load this workout yet." : "No exercises added yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#8E8E93"))
                .padding(.vertical, 10)
        } else {
            VStack(spacing: 12) {
                ForEach(exercises) { exercise in
                    sessionExerciseRow(
                        exercise,
                        subtitleOverride: isQuickStarter ? quickStarterRowSubtitle(for: exercise) : nil
                    )
                }
            }
        }
    }

    private var setLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set Log")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            exerciseRowsContent
        }
    }

    private func quickStarterDisplayName(for exercise: Exercise) -> String {
        let n = exercise.name.lowercased()
        if n.contains("lat") && n.contains("pulldown") {
            return "Lats Pull Down"
        }
        return exercise.name
    }

    private func quickStarterRowSubtitle(for exercise: Exercise) -> String {
        let n = exercise.name.lowercased()
        if n.contains("lat") && n.contains("pulldown") {
            return "Back • Strength"
        }
        if n.contains("seated") && n.contains("row") {
            return "Back • Hypertrophy"
        }
        if n.contains("pullover") {
            return "Chest/Back • Strength"
        }
        return sessionSubtitle(for: exercise)
    }

    private func sessionExerciseRow(_ exercise: Exercise, subtitleOverride: String? = nil) -> some View {
        let title = isQuickStarter ? quickStarterDisplayName(for: exercise) : exercise.name
        let sub = subtitleOverride ?? sessionSubtitle(for: exercise)
        return HStack(alignment: .center, spacing: 14) {
            ExerciseRowThumb(urlString: exercise.thumbnailURL)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .lineLimit(1)
                Text(sub)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
            Spacer(minLength: 8)
            DragHandleSixDots()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var addExerciseButton: some View {
        Button {
            showExerciseSelection = true
            HapticFeedback.impact()
        } label: {
            Text("Add Exercise")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var techniqueGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Technique guide")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            if exercises.isEmpty {
                Text(isQuickStarter ? "Clips will appear when exercises load." : "Add exercises to see technique clips.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8E8E93"))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(exercises.prefix(6).enumerated()), id: \.element.id) { _, exercise in
                            techniqueCard(
                                exercise,
                                displayTitle: isQuickStarter ? quickStarterDisplayName(for: exercise) : nil
                            )
                        }
                    }
                    .padding(.trailing, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func techniqueCard(_ exercise: Exercise, displayTitle: String? = nil) -> some View {
        let rawName = displayTitle ?? exercise.name
        let name = shortExerciseName(rawName)
        let pillLabel = isQuickStarter ? "Easy" : difficultyPillText(for: exercise)
        let hasVideo = exercise.hasPlayableMedia

        let card = ZStack(alignment: .bottom) {
            ExerciseCardThumb(urlString: exercise.thumbnailURL)
                .frame(width: 280, height: 160)
                .clipped()
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.25), Color.black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pillLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#0F5132"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(easyBadgeBg)
                        .clipShape(Capsule())
                    Text(name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                        .lineLimit(2)
                        .frame(maxWidth: 200, alignment: .leading)
                }
                Spacer(minLength: 8)
                if hasVideo {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.95))
                            .frame(width: 44, height: 44)
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 280, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

        if hasVideo {
            Button {
                selectedTechniqueExercise = exercise
                HapticFeedback.impact(style: .light)
            } label: {
                card
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(name), play technique video")
        } else {
            card
                .accessibilityLabel(name)
        }
    }

    private var aiOptimizedCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                Text("AI OPTIMIZED")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.6)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(easyBadgeGreen)
            .clipShape(Capsule())

            Text("Strategy for Your Fitness Twin")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            Text(aiStrategySubtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(Array(exercises.prefix(3).enumerated()), id: \.element.id) { idx, exercise in
                    HStack(alignment: .center) {
                        Text(exercise.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(recommendationText(for: exercise, index: idx))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.72))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [aiPurpleA, Color(hex: "#8B3DEE"), aiPurpleB],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: aiPurpleA.opacity(0.25), radius: 12, x: 0, y: 6)
    }

    private var startSessionButton: some View {
        VStack {
            Divider().opacity(0)
            Button {
                guard !exercises.isEmpty else { return }
                showSessionLog = true
                HapticFeedback.impact()
            } label: {
                Text("Start Session")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(exercises.isEmpty ? Color(hex: "#F2B074") : primaryOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: primaryOrange.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
        .background(Color(hex: "#F5F5F7").opacity(0.96))
    }

    private func loadExercises() async {
        isLoading = true
        let ids = workout.exercises
        let list = await WorkoutService.shared.fetchExercisesMerged(ids: ids)
        await MainActor.run {
            exercises = list
            isLoading = false
            if ids.isEmpty {
                loadError = nil
            } else if list.isEmpty {
                loadError = "We couldn't load this workout's exercises yet. Please try again."
            } else {
                loadError = nil
            }
        }
    }

    private func sessionSubtitle(for exercise: Exercise) -> String {
        let area: String
        if exercise.muscleGroups.count >= 2 {
            area = exercise.muscleGroups.prefix(2).map { $0.displayName }.joined(separator: "/")
        } else if let g = exercise.muscleGroups.first {
            area = g.displayName
        } else {
            area = "General"
        }
        return "\(area) • \(focusLabel(for: exercise))"
    }

    private func focusLabel(for exercise: Exercise) -> String {
        switch exercise.difficultyLevel {
        case .beginner:
            return "Strength"
        case .intermediate, .advanced:
            return "Hypertrophy"
        case .allLevels:
            return "Strength"
        }
    }

    private var aiStrategySubtitle: String {
        let kg = displayWeightKg
        let goal = quotedFitnessGoal
        return "Based on your \(String(format: "%.0f", kg))kg weight and \(goal) goal."
    }

    private var displayWeightKg: Double {
        if let w = authViewModel.currentUser?.weight, w > 0 { return w }
        return 85
    }

    private var quotedFitnessGoal: String {
        if let g = authViewModel.currentUser?.fitnessGoal {
            return "'\(g.displayName)'"
        }
        return "'General fitness'"
    }

    private func recommendationText(for exercise: Exercise, index: Int) -> String {
        let sets = exercise.sets ?? (4 - min(index, 1))
        let reps = exercise.reps ?? (index == 0 ? 10 : (index == 1 ? 12 : 15))
        return "\(sets) sets × \(reps) reps"
    }

    private func shortExerciseName(_ full: String) -> String {
        if full.count <= 24 { return full }
        return String(full.prefix(22)) + "…"
    }

    private func difficultyPillText(for exercise: Exercise) -> String {
        switch exercise.difficultyLevel {
        case .beginner:
            return "Easy"
        case .intermediate:
            return "Moderate"
        case .advanced:
            return "Advanced"
        case .allLevels:
            return "All levels"
        }
    }
}

/// 2×3 drag handle (matches common “grip” affordance in mocks).
private struct DragHandleSixDots: View {
    private let dot = Color(hex: "#C7C7CC")

    var body: some View {
        HStack(spacing: 3) {
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(dot)
                        .frame(width: 3.5, height: 3.5)
                }
            }
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(dot)
                        .frame(width: 3.5, height: 3.5)
                }
            }
        }
        .accessibilityLabel("Reorder")
    }
}

private struct ExerciseRowThumb: View {
    let urlString: String?
    var body: some View {
        Group {
            if let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            Color(hex: "#E8E8ED")
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#AEAEAE"))
        }
    }
}

private struct ExerciseCardThumb: View {
    let urlString: String?
    var body: some View {
        Group {
            if let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
    }

    private var fallback: some View {
        LinearGradient(
            colors: [Color(hex: "#6B6B6B"), Color(hex: "#2F2F2F")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview("Standard") {
    WorkoutSessionStartView(
        workout: Workout(
            title: "Pull Day",
            description: "",
            category: .strength,
            difficulty: .intermediate,
            duration: 55,
            exercises: [],
            userId: "u1"
        ),
        userId: "u1"
    )
    .environmentObject(AuthViewModel())
}

#Preview("Quick starter") {
    WorkoutSessionStartView(
        workout: Workout.quickStarterTemplate(),
        userId: "u1",
        presentation: .quickStarterFirstWorkout
    )
    .environmentObject(AuthViewModel())
}
