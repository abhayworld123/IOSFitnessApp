import SwiftUI

struct UserWorkoutDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var exercises: [Exercise] = []
    @State private var currentWorkout: Workout
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showVideoPlayer = false
    @State private var showDeleteAlert = false
    @State private var showExerciseSelection = false
    @State private var isDeleting = false
    @State private var selectedExercise: Exercise?
    @State private var selectedVideoExercise: Exercise?
    @State private var selectedExerciseForLog: Exercise?
    @StateObject private var createWorkoutViewModel = CreateWorkoutViewModel()
    
    private let workoutService = WorkoutService.shared
    
    init(workout: Workout) {
        self.workout = workout
        _currentWorkout = State(initialValue: workout)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        headerSection(currentWorkout)
                        
                        // Set Log Section
                        setLogSection
                        
                        // Add Exercise Button
                        addExerciseButton
                        
                        // How to Section
                        if !exercises.isEmpty {
                            howToSection
                        }
                        
                        // Suggested Plan Section
                        if !exercises.isEmpty {
                            suggestedPlanSection
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadExercises()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutUpdated"))) { _ in
            // Refresh workout and exercises when workout is updated
            Task {
                await refreshWorkout()
                await loadExercises()
            }
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoPlayerView(workout: currentWorkout)
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise, workout: currentWorkout)
        }
        .sheet(item: $selectedVideoExercise) { exercise in
            // Show exercise video or detail
            ExerciseDetailView(exercise: exercise, workout: currentWorkout)
        }
        .sheet(item: $selectedExerciseForLog) { exercise in
            ExerciseLogView(
                exercise: exercise,
                workout: currentWorkout,
                userId: authViewModel.currentUser?.id ?? ""
            )
        }
        .fullScreenCover(isPresented: $showExerciseSelection) {
            ExerciseSelectionView(
                workoutName: currentWorkout.title,
                workoutDescription: currentWorkout.description,
                viewModel: createWorkoutViewModel,
                existingWorkout: currentWorkout,
                onDismiss: nil
            )
            .environmentObject(authViewModel)
        }
        .alert("Delete Workout", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
        } message: {
            Text("Are you sure you want to delete '\(workout.title)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    
    private func headerSection(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Session")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#007AFF"))
            }
            
            Text(workout.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Set Log Section
    
    private var setLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Set Log")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            if exercises.isEmpty {
                Text("No exercises added yet")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8E8E93"))
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        SetLogExerciseRow(
                            exercise: exercise,
                            onTap: {
                                selectedExerciseForLog = exercise
                            }
                        )
                        
                        if index < exercises.count - 1 {
                            Divider()
                                .background(Color(hex: "#E5E5EA"))
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Add Exercise Button
    
    private var addExerciseButton: some View {
        Button(action: {
            showExerciseSelection = true
            HapticFeedback.impact()
        }) {
            Text("Add Exercise")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .cornerRadius(12)
        }
    }
    
    // MARK: - How to Section
    
    private var howToSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        HowToVideoThumbnail(
                            exercise: exercise,
                            onTap: {
                                selectedVideoExercise = exercise
                            }
                        )
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
        }
    }
    
    // MARK: - Suggested Plan Section
    
    private var suggestedPlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Plan")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            VStack(spacing: 0) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    SuggestedPlanRow(
                        exercise: exercise,
                        index: index + 1
                    )
                    
                    if index < exercises.count - 1 {
                        Divider()
                            .background(Color(hex: "#E5E5EA"))
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading exercises...")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#8E8E93"))
        }
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "#8E8E93").opacity(0.5))
            
            Text("Failed to Load Exercises")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "#8E8E93"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Retry") {
                Task {
                    await loadExercises()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Refresh Workout
    
    private func refreshWorkout() async {
        do {
            if let updatedWorkout = try await workoutService.fetchWorkout(id: workout.id) {
                currentWorkout = updatedWorkout
            }
        } catch {
            print("Error refreshing workout: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Load Exercises
    
    private func loadExercises() async {
        isLoading = true
        errorMessage = nil
        
        guard !currentWorkout.exercises.isEmpty else {
            isLoading = false
            return
        }
        
        do {
            // Try to fetch from Firebase first
            var fetchedExercises = try await workoutService.fetchExercises(ids: currentWorkout.exercises)
            
            // If some exercises are missing from Firebase, try loading from JSON
            if fetchedExercises.count < currentWorkout.exercises.count {
                print("Some exercises not found in Firebase, trying JSON fallback...")
                let jsonExercises = try ExerciseDataService.loadExercisesFromJSON()
                
                // Create a dictionary for quick lookup
                let jsonExerciseDict = Dictionary(uniqueKeysWithValues: jsonExercises.map { ($0.id, $0) })
                
                // Fill in missing exercises from JSON
                var allExercises: [Exercise] = []
                for exerciseId in currentWorkout.exercises {
                    if let firebaseExercise = fetchedExercises.first(where: { $0.id == exerciseId }) {
                        allExercises.append(firebaseExercise)
                    } else if let jsonExercise = jsonExerciseDict[exerciseId] {
                        allExercises.append(jsonExercise)
                        print("Found exercise \(exerciseId) in JSON")
                    } else {
                        print("Exercise \(exerciseId) not found in Firebase or JSON")
                    }
                }
                
                exercises = allExercises
            } else {
                exercises = fetchedExercises
            }
        } catch {
            // If Firebase fetch fails, try JSON as fallback
            print("Firebase fetch failed, trying JSON fallback: \(error.localizedDescription)")
            do {
                let jsonExercises = try ExerciseDataService.loadExercisesFromJSON()
                let jsonExerciseDict = Dictionary(uniqueKeysWithValues: jsonExercises.map { ($0.id, $0) })
                
                exercises = currentWorkout.exercises.compactMap { exerciseId in
                    jsonExerciseDict[exerciseId]
                }
            } catch {
                errorMessage = "Failed to load exercises. Please try again."
                print("Error loading exercises from JSON: \(error.localizedDescription)")
            }
        }
        
        print("Loaded \(exercises.count) exercises out of \(currentWorkout.exercises.count) expected")
        isLoading = false
    }
    
    // MARK: - Delete Workout
    
    private func deleteWorkout() {
        isDeleting = true
        HapticFeedback.impact()
        
        Task {
            do {
                try await workoutService.deleteWorkout(id: workout.id)
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                    // Post notification to refresh dashboard
                    NotificationCenter.default.post(name: NSNotification.Name("WorkoutDeleted"), object: nil)
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "Failed to delete workout. Please try again."
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Set Log Exercise Row

private struct SetLogExerciseRow: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                Spacer()
                
                // Orange circular arrow icon with custom SVG
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: 32, height: 32)
                    
                    ArrowRightIcon()
                        .frame(width: 7, height: 12)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Arrow Right Icon (SVG)

private struct ArrowRightIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Scale the SVG coordinates to fit the rect
        let scaleX = rect.width / 7.0
        let scaleY = rect.height / 12.0
        let scale = min(scaleX, scaleY)
        
        // Center the path
        let offsetX = (rect.width - (7.0 * scale)) / 2.0
        let offsetY = (rect.height - (12.0 * scale)) / 2.0
        
        // Draw the arrow path: M0.75 0.75L5.75 5.75L0.75 10.75
        path.move(to: CGPoint(x: offsetX + 0.75 * scale, y: offsetY + 0.75 * scale))
        path.addLine(to: CGPoint(x: offsetX + 5.75 * scale, y: offsetY + 5.75 * scale))
        path.addLine(to: CGPoint(x: offsetX + 0.75 * scale, y: offsetY + 10.75 * scale))
        
        return path
    }
}

extension ArrowRightIcon: View {
    var body: some View {
        self
            .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}

// MARK: - How to Video Thumbnail

private struct HowToVideoThumbnail: View {
    let exercise: Exercise
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Video thumbnail placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#FF9500").opacity(0.6),
                                Color(hex: "#FF9500").opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Gradient Overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content Overlay
                VStack {
                    HStack {
                        // Difficulty Badge
                        Text(difficultyTag)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#FF9500"))
                            .cornerRadius(6)
                        
                        Spacer()
                    }
                    .padding(12)
                    
                    Spacer()
                    
                    // Title and Play Button
                    HStack {
                        Text(exercise.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .padding(12)
                }
            }
            .frame(width: 240, height: 140)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var difficultyTag: String {
        switch exercise.difficultyLevel {
        case .beginner:
            return "Easy"
        case .intermediate:
            return "Medium"
        case .advanced:
            return "Hard"
        case .allLevels:
            return "All"
        }
    }
}

// MARK: - Suggested Plan Row

private struct SuggestedPlanRow: View {
    let exercise: Exercise
    let index: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Number circle
            Text("\(index)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#8E8E93"))
                .frame(width: 32, height: 32)
                .background(Color(hex: "#E5E5EA"))
                .clipShape(Circle())
            
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                if let sets = exercise.sets, let reps = exercise.reps {
                    Text("\(sets) sets - \(reps) reps")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8E8E93"))
                } else if let duration = exercise.duration {
                    Text("\(duration) seconds")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    UserWorkoutDetailView(
        workout: Workout(
            title: "Pull Day",
            description: "Back and biceps workout",
            category: .strength,
            difficulty: .intermediate,
            duration: 45,
            exercises: ["ex1", "ex2", "ex3"],
            caloriesBurned: 300
        )
    )
    .environmentObject(AuthViewModel())
}
