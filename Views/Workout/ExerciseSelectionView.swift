import SwiftUI

// Exercise session builder — Trakkit (Figma: https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=650-1352 )

struct ExerciseSelectionView: View {
    let workoutName: String
    let workoutDescription: String
    @ObservedObject var viewModel: CreateWorkoutViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let onDismiss: (() -> Void)?
    let existingWorkout: Workout?
    @State private var showSuccessAlert = false
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var sessionPresentation: SessionPresentation?
    
    private let primaryOrange = Color(hex: "#FF9500")
    private let bottomChromeHeight: CGFloat = 168
    
    init(workoutName: String, workoutDescription: String, viewModel: CreateWorkoutViewModel, existingWorkout: Workout? = nil, onDismiss: (() -> Void)? = nil) {
        self.workoutName = workoutName
        self.workoutDescription = workoutDescription
        self.viewModel = viewModel
        self.existingWorkout = existingWorkout
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                
                filterChips
                    .padding(.bottom, 12)
                
                Group {
                    if viewModel.isLoading && viewModel.allExercises.isEmpty {
                        loadingView
                    } else if let err = viewModel.errorMessage, !err.isEmpty, viewModel.allExercises.isEmpty, !viewModel.isLoading {
                        LoadFailureFallbackView(
                            message: err,
                            onRetry: { Task { await viewModel.fetchExercises() } },
                            onGoBack: { dismiss() }
                        )
                    } else {
                        exerciseListRegion
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            bottomChrome
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.userId = authViewModel.currentUser?.id
            
            if let existing = existingWorkout {
                viewModel.loadExistingWorkout(existing)
            }
            
            if viewModel.allExercises.isEmpty {
                Task {
                    await viewModel.fetchExercises()
                }
            }
        }
        .alert(existingWorkout != nil ? "Workout Updated!" : "Workout Created!", isPresented: $showSuccessAlert) {
            Button("OK") {
                if existingWorkout == nil {
                    viewModel.reset()
                    dismiss()
                    onDismiss?()
                } else {
                    dismiss()
                }
                
                if existingWorkout != nil {
                    NotificationCenter.default.post(name: NSNotification.Name("WorkoutUpdated"), object: nil)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("WorkoutCreated"), object: nil)
                }
            }
        } message: {
            Text(existingWorkout != nil
                 ? "Your workout '\(workoutName)' has been updated successfully."
                 : "Your workout '\(workoutName)' has been created successfully.")
        }
        .alert("Save Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(item: $sessionPresentation) { ctx in
            WorkoutSessionLogView(
                workout: ctx.workout,
                exercises: ctx.exercises,
                userId: authViewModel.currentUser?.id ?? "",
                onFinished: { saved in
                    sessionPresentation = nil
                    guard saved else { return }
                    if existingWorkout == nil {
                        viewModel.reset()
                        dismiss()
                        onDismiss?()
                        NotificationCenter.default.post(name: NSNotification.Name("WorkoutCreated"), object: nil)
                    } else {
                        dismiss()
                        NotificationCenter.default.post(name: NSNotification.Name("WorkoutUpdated"), object: nil)
                    }
                }
            )
            .environmentObject(authViewModel)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(hex: "#1A1A1A"))
            }
            .accessibilityLabel("Go back")
            
            (Text("BUILD YOUR ")
                .foregroundColor(Color(hex: "#1A1A1A"))
             + Text("SESSION")
                .foregroundColor(primaryOrange))
            .font(.system(size: 26, weight: .bold))
            .fixedSize(horizontal: false, vertical: true)
            
            Text("Select exercises to generate your high-performance circuit.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "#8E8E8E"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.white)
    }
    
    // MARK: - Search
    
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#AEAEAE"))
            
            TextField("Search exercises...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .onChange(of: viewModel.searchQuery) { _, newValue in
                    viewModel.searchExercises(query: newValue)
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.searchExercises(query: "")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(hex: "#AEAEAE"))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#E8E8E8"), lineWidth: 1)
        )
    }
    
    // MARK: - Filter chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ExerciseCatalogFilter.allCases, id: \.self) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func filterChip(_ filter: ExerciseCatalogFilter) -> some View {
        let selected = viewModel.exerciseCatalogFilter == filter
        return Button {
            viewModel.setExerciseCatalogFilter(filter)
            HapticFeedback.impact()
        } label: {
            Text(filter.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selected ? .white : Color(hex: "#5C5C5C"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(selected ? primaryOrange : Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selected ? Color.clear : Color(hex: "#E0E0E0"), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - List
    
    private var exerciseListRegion: some View {
        Group {
            if viewModel.allExercises.isEmpty {
                emptyCatalogView
            } else if viewModel.filteredExercises.isEmpty {
                pickerEmptyMessage("Try another filter or search term.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredExercises) { exercise in
                            ExerciseSelectionRow(
                                exercise: exercise,
                                isSelected: viewModel.isExerciseSelected(exercise.id),
                                useAIPickStyle: exercise.useSessionAIPickStyling,
                                subtitle: sessionRowSubtitle(exercise),
                                onTap: {
                                    viewModel.toggleExerciseSelection(exercise.id)
                                    HapticFeedback.impact()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, bottomChromeHeight + 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func sessionRowSubtitle(_ exercise: Exercise) -> String {
        let muscle = exercise.muscleGroups.first?.displayName ?? "Full Body"
        let kind: String
        if ExerciseCatalogFilter.recovery.matches(exercise) {
            kind = "Recovery"
        } else if exercise.muscleGroups.contains(.cardio) {
            kind = "Cardio"
        } else {
            kind = "Strength"
        }
        return "\(muscle) • \(kind)"
    }
    
    private func pickerEmptyMessage(_ message: String) -> some View {
        VStack {
            Spacer(minLength: 0)
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#8E8E8E"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading
    
    private var loadingView: some View {
        VStack {
            Spacer(minLength: 0)
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading exercises...")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#8E8E8E"))
                .padding(.top, 16)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty catalog
    
    private var emptyCatalogView: some View {
        VStack {
            Spacer(minLength: 0)
            Image(systemName: "figure.run")
                .font(.system(size: 56))
                .foregroundColor(Color(hex: "#D0D0D0"))
            Text("No Exercises Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1A1A1A"))
                .padding(.top, 16)
            Text("No exercises available. Please add exercises to the database.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#8E8E8E"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Bottom summary (fixed)
    
    private var bottomChrome: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(0.92),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 36)
            
            VStack(spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    thumbnailStack
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.selectedExercises.count) Exercises Selected")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                        Text("Estimated duration: \(viewModel.estimatedSessionMinutes) mins")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "#8E8E8E"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(spacing: 12) {
                    Button(action: doneTapped) {
                        Text("Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(primaryOrange)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: startSessionTapped) {
                        Group {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Start Session")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            viewModel.canSaveWorkout() && !isSaving
                                ? primaryOrange
                                : Color.gray.opacity(0.45)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.canSaveWorkout() || isSaving)
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: -4)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(Color.clear)
    }
    
    private var thumbnailStack: some View {
        let ordered = viewModel.selectedExercisesInCatalogOrder
        let maxVisible = 4
        let visible = Array(ordered.prefix(maxVisible))
        
        return HStack(spacing: -14) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, exercise in
                ExercisePickerThumbnail(urlString: exercise.thumbnailURL, size: 44)
                    .zIndex(Double(maxVisible - index))
            }
            if ordered.isEmpty {
                Circle()
                    .fill(Color(hex: "#EFEFEF"))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#C4C4C4"))
                    )
            }
            if ordered.count > maxVisible {
                Text("+\(ordered.count - maxVisible)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#5C5C5C"))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: "#F0F0F0"))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }
    
    // MARK: - Actions
    
    private func doneTapped() {
        if existingWorkout != nil {
            saveWorkout()
        } else {
            dismiss()
        }
    }
    
    private func startSessionTapped() {
        guard viewModel.canSaveWorkout() else {
            HapticFeedback.error()
            return
        }
        saveWorkout(openSessionAfterSave: true)
    }
    
    private func orderedExercises(from workout: Workout) -> [Exercise] {
        workout.exercises.compactMap { eid in viewModel.allExercises.first { $0.id == eid } }
    }
    
    private func saveWorkout(openSessionAfterSave: Bool = false) {
        isSaving = true
        HapticFeedback.impact()
        
        Task {
            do {
                let saved = try await viewModel.createWorkout()
                let ordered = orderedExercises(from: saved)
                await MainActor.run {
                    isSaving = false
                    AnalyticsService.shared.trackFeatureUsage(featureName: "workout_created", parameters: [
                        "workout_name": workoutName,
                        "exercise_count": viewModel.selectedExercises.count
                    ])
                    if openSessionAfterSave, !ordered.isEmpty {
                        sessionPresentation = SessionPresentation(workout: saved, exercises: ordered)
                    } else {
                        showSuccessAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Session handoff

private struct SessionPresentation: Identifiable {
    let workout: Workout
    let exercises: [Exercise]
    var id: String { workout.id }
}

// MARK: - Thumbnail (picker strip)

private struct ExercisePickerThumbnail: View {
    let urlString: String?
    var size: CGFloat = 44
    
    var body: some View {
        Group {
            if let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }
    
    private var placeholder: some View {
        ZStack {
            Color(hex: "#E8E8ED")
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#AEAEAE"))
        }
    }
}

// MARK: - Exercise row

struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let useAIPickStyle: Bool
    let subtitle: String
    let onTap: () -> Void
    
    private let primaryOrange = Color(hex: "#FF9500")
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                thumbnailBlock
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(titleColor)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(hex: "#8E8E8E"))
                    
                    if useAIPickStyle {
                        Text("✨ PERFECT FOR FLOW")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppConstants.TrakkitAI.title.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                selectionIndicator
            }
            .padding(12)
            .background(rowBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(exercise.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var titleColor: Color {
        if useAIPickStyle && !isSelected {
            return AppConstants.TrakkitAI.emphasisPurple
        }
        return Color(hex: "#1A1A1A")
    }
    
    @ViewBuilder
    private var rowBackground: some View {
        if useAIPickStyle {
            LinearGradient(
                colors: [AppConstants.TrakkitAI.rowGradientTop, AppConstants.TrakkitAI.rowGradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return primaryOrange
        }
        if useAIPickStyle {
            return AppConstants.TrakkitAI.rowBorder
        }
        return Color(hex: "#E8E8E8")
    }
    
    private var thumbnailBlock: some View {
        ZStack(alignment: .topLeading) {
            ExerciseRowThumbnail(urlString: exercise.thumbnailURL, size: 56, cornerRadius: 10)
            
            if useAIPickStyle {
                Text("AI PICK")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#43A047"))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .offset(x: -4, y: -4)
            }
        }
    }
    
    private var selectionIndicator: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(primaryOrange)
                    .frame(width: 26, height: 26)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else if useAIPickStyle {
                Circle()
                    .stroke(AppConstants.TrakkitAI.iconBox, lineWidth: 2)
                    .frame(width: 26, height: 26)
            } else {
                Circle()
                    .stroke(primaryOrange, lineWidth: 2)
                    .frame(width: 26, height: 26)
            }
        }
        .frame(width: 32, height: 32)
    }
}

private struct ExerciseRowThumbnail: View {
    let urlString: String?
    var size: CGFloat = 56
    var cornerRadius: CGFloat = 10
    
    var body: some View {
        Group {
            if let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private var placeholder: some View {
        ZStack {
            Color(hex: "#E8E8ED")
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "#AEAEAE"))
        }
    }
}

// MARK: - Exercise + AI styling (until model has a flag)

private extension Exercise {
    /// Curated “AI pick” row styling — name/description heuristics.
    var useSessionAIPickStyling: Bool {
        let n = name.lowercased()
        let d = description.lowercased()
        if n.contains("stretchflow") || n.contains("thoracic stretch") { return true }
        if n.contains("flow") && (n.contains("stretch") || d.contains("flow")) { return true }
        return false
    }
}

#Preview {
    ExerciseSelectionView(
        workoutName: "Pull Day",
        workoutDescription: "Back and biceps workout",
        viewModel: CreateWorkoutViewModel(),
        existingWorkout: nil,
        onDismiss: nil
    )
    .environmentObject(AuthViewModel())
}
