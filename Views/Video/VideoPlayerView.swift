import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    @StateObject private var viewModel: VideoPlayerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showControlsTimer: Timer?
    @State private var showCompletionAlert = false
    @State private var hasCompleted = false
    @State private var isFullScreen = false
    @State private var showExerciseList = false
    @State private var exercises: [Exercise] = []
    @State private var currentExerciseIndex: Int? = nil
    
    private let workout: Workout
    private let dayId: String?
    private let planViewModel: WorkoutPlanViewModel?
    
    init(workout: Workout, dayId: String? = nil, planViewModel: WorkoutPlanViewModel? = nil) {
        let viewModel = VideoPlayerViewModel(workout: workout, dayId: dayId, planViewModel: planViewModel)
        _viewModel = StateObject(wrappedValue: viewModel)
        self.workout = workout
        self.dayId = dayId
        self.planViewModel = planViewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Video Player Section
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    // Video Player - Conditional rendering based on source type
            if viewModel.videoSourceType == .youtube || viewModel.videoSourceType == .vimeo {
                // Web-based video player (YouTube/Vimeo)
                if let embedURL = viewModel.embedURL {
                    WebVideoPlayerView(
                        embedURL: embedURL,
                        isLoading: $viewModel.isLoading,
                        errorMessage: $viewModel.errorMessage
                    )
                    .ignoresSafeArea()
                    .onTapGesture {
                        toggleControls()
                    }
                    .overlay(
                        // Loading Indicator
                        Group {
                            if viewModel.isLoading {
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    Text("Loading video...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                }
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                            }
                        }
                    )
                    .overlay(
                        // Error Message
                        Group {
                            if let errorMessage = viewModel.errorMessage {
                                VStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                    
                                    Text(errorMessage)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Retry") {
                                        viewModel.setupPlayer()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(16)
                            }
                        }
                    )
                } else {
                    // No embed URL available
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        Text("Invalid video URL")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
            } else if let player = viewModel.player {
                // Direct URL video player (AVPlayer)
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        toggleControls()
                    }
                    .background(
                        VideoPlayerLayerView(player: player, viewModel: viewModel)
                            .opacity(0)
                    )
                    .overlay(
                        // Controls Overlay
                        Group {
                            if viewModel.showControls && !viewModel.isLoading {
                                VideoControlsView(viewModel: viewModel)
                                    .transition(.opacity)
                            }
                        }
                    )
                    .overlay(
                        // Buffering Indicator
                        Group {
                            if viewModel.isBuffering || viewModel.isLoading {
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    if viewModel.isLoading {
                                        Text("Loading video...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(.top, 8)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(12)
                            }
                        }
                    )
                    .overlay(
                        // Error Message
                        Group {
                            if let errorMessage = viewModel.errorMessage {
                                VStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                    
                                    Text(errorMessage)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Retry") {
                                        viewModel.setupPlayer()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(16)
                            }
                        }
                    )
            } else {
                // No player available
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading video...")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            
            // Top Bar
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Workout Title
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(workout.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("\(workout.duration) min • \(workout.category.displayName)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Full-screen toggle
                    Button(action: {
                        withAnimation {
                            isFullScreen.toggle()
                        }
                    }) {
                        Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 8)
                    
                    // Manual completion button for YouTube/Vimeo videos
                    if (viewModel.videoSourceType == .youtube || viewModel.videoSourceType == .vimeo) && !hasCompleted && dayId != nil {
                        Button(action: {
                            hasCompleted = true
                            markWorkoutComplete()
                        }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.green.opacity(0.8))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.7),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(viewModel.showControls ? 1 : 0)
                
                Spacer()
            }
            }
            .frame(height: isFullScreen ? geometry.size.height : geometry.size.height * 0.6)
                
                // Exercise List Section (only show when not full screen)
                if !isFullScreen && !exercises.isEmpty {
                    exerciseListView
                        .frame(height: geometry.size.height * 0.4)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await loadExercises()
                await viewModel.loadProgress()
            }
            startControlsTimer()
            setupBackgroundNotifications()
            AnalyticsService.shared.trackVideoStart(workoutId: workout.id, workoutTitle: workout.title)
        }
        .onDisappear {
            Task {
                await viewModel.saveProgress()
            }
            viewModel.cleanup()
            stopControlsTimer()
        }
        .alert("Workout Complete!", isPresented: $showCompletionAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Great job! You've completed \(workout.title)")
        }
        .onChange(of: viewModel.currentTime) { newTime in
            // Auto-hide controls after 3 seconds (only for direct URL videos)
            if viewModel.videoSourceType == .directURL && viewModel.isPlaying {
                startControlsTimer()
            }
            
            // Check if workout is complete (90% watched) - only for direct URL videos
            if viewModel.videoSourceType == .directURL && !hasCompleted && viewModel.duration > 0 {
                let progress = newTime / viewModel.duration
                if progress >= 0.9 {
                    hasCompleted = true
                    markWorkoutComplete()
                }
            }
        }
    }
    
    private func toggleControls() {
        withAnimation {
            viewModel.showControls.toggle()
        }
        
        if viewModel.showControls {
            startControlsTimer()
        } else {
            stopControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        stopControlsTimer()
        showControlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if viewModel.isPlaying {
                withAnimation {
                    viewModel.showControls = false
                }
            }
        }
    }
    
    private func stopControlsTimer() {
        showControlsTimer?.invalidate()
        showControlsTimer = nil
    }
    
    private func markWorkoutComplete() {
        Task {
            await viewModel.saveProgress()
            await viewModel.markWorkoutComplete()
            AnalyticsService.shared.trackVideoComplete(
                workoutId: workout.id,
                workoutTitle: workout.title,
                duration: viewModel.duration
            )
            if let planId = dayId {
                AnalyticsService.shared.trackWorkoutComplete(workoutId: workout.id, planId: planId)
            }
            showCompletionAlert = true
            HapticFeedback.success()
        }
    }
    
    // MARK: - Exercise List View
    
    private var exerciseListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercises")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showExerciseList.toggle()
                    }
                }) {
                    Image(systemName: showExerciseList ? "chevron.down" : "chevron.up")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if showExerciseList {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseRow(
                                exercise: exercise,
                                isActive: currentExerciseIndex == index,
                                onTap: {
                                    // Navigate to exercise detail or jump to exercise in video
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Load Exercises
    
    private func loadExercises() async {
        guard !workout.exercises.isEmpty else {
            // No exercises to resolve hero media from; fall back to the workout video configuration.
            viewModel.setHeroMediaURLString(nil)
            return
        }
        exercises = await WorkoutService.shared.fetchExercisesMerged(ids: workout.exercises)

        // Hero video source: use exercise media (merged exercise catalog), not `Workout.videoURL`.
        let heroAnimation = exercises
            .compactMap { $0.animationURL }
            .first(where: { isDirectVideoURLString($0) })
        
        if let heroAnimation {
            viewModel.setHeroMediaURLString(heroAnimation)
        } else {
            // No direct-video media available from exercise catalog; fall back to workout video config.
            viewModel.setHeroMediaURLString(nil)
        }
    }

    private func isDirectVideoURLString(_ string: String) -> Bool {
        let lower = string.lowercased()
        let pathPart = lower.split(separator: "?").first.map(String.init) ?? lower
        let ext = [".mp4", ".webm", ".mov", ".m4v"]
        if ext.contains(where: { pathPart.hasSuffix($0) }) { return true }
        return ext.contains { lower.contains($0) }
    }
    
    // MARK: - Background Notifications
    
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            viewModel.pause()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Optionally resume playback
        }
    }
}

// MARK: - Exercise Row

struct ExerciseRow: View {
    let exercise: Exercise
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Active indicator
                if isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let sets = exercise.sets, let reps = exercise.reps {
                        Text("\(sets) sets × \(reps) reps")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    } else if let duration = exercise.duration {
                        Text("\(duration) seconds")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(isActive ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}


#Preview {
    VideoPlayerView(workout: Workout(
        title: "Full Body HIIT",
        description: "High-intensity interval training",
        category: .hiit,
        difficulty: .intermediate,
        duration: 30,
        videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    ))
}

