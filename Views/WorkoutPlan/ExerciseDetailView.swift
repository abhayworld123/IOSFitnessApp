import SwiftUI
import Lottie
import AVKit

struct ExerciseDetailView: View {
    let exercise: Exercise
    let workout: Workout?
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var timerSeconds: Int = 0
    @State private var isTimerRunning = false
    @State private var timer: Timer?
    @State private var showVideoPlayer = false
    @State private var animationURL: URL?
    @State private var animationError: String?
    @State private var exerciseVideoPlayer: AVPlayer?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Exercise Name
                        Text(exercise.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Lottie JSON or direct video (e.g. MP4 from R2)
                        if let player = exerciseVideoPlayer {
                            VideoPlayer(player: player)
                                .frame(height: 300)
                                .cornerRadius(AppConstants.Design.cornerRadius)
                                .padding(.horizontal, 20)
                        } else if let animationURL = animationURL {
                            RemoteLottieAnimationView(url: animationURL)
                                .frame(height: 300)
                                .cornerRadius(AppConstants.Design.cornerRadius)
                                .padding(.horizontal, 20)
                        } else if let animationError = animationError {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                                Text(animationError)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                            }
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(AppConstants.Design.cornerRadius)
                            .padding(.horizontal, 20)
                        } else {
                            // Placeholder while loading
                            ProgressView()
                                .frame(height: 300)
                                .frame(maxWidth: .infinity)
                                .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                                .cornerRadius(AppConstants.Design.cornerRadius)
                                .padding(.horizontal, 20)
                        }
                        
                        // Exercise Details Card
                        VStack(spacing: 16) {
                            // Sets and Reps / Duration
                            if let sets = exercise.sets, let reps = exercise.reps {
                                ExerciseDetailRow(
                                    icon: "repeat",
                                    title: "Sets × Reps",
                                    value: "\(sets) × \(reps)"
                                )
                            } else if let duration = exercise.duration {
                                ExerciseDetailRow(
                                    icon: "clock",
                                    title: "Duration",
                                    value: "\(duration) seconds"
                                )
                            }
                            
                            Divider()
                                .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                            
                            // Rest Time
                            ExerciseDetailRow(
                                icon: "pause.circle",
                                title: "Rest Time",
                                value: "\(exercise.restTime) seconds"
                            )
                            
                            Divider()
                                .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                            
                            // Muscle Groups
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "figure.strengthtraining.functional")
                                        .foregroundColor(AppConstants.Colors.primary)
                                        .frame(width: 24)
                                    Text("Muscle Groups")
                                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                                    Spacer()
                                }
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(exercise.muscleGroups, id: \.self) { group in
                                        Text(group.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppConstants.Colors.primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            Divider()
                                .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                            
                            // Difficulty
                            ExerciseDetailRow(
                                icon: "chart.bar",
                                title: "Difficulty",
                                value: exercise.difficultyLevel.displayName
                            )
                        }
                        .padding()
                        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(AppConstants.Design.cornerRadius)
                        .padding(.horizontal, 20)
                        
                        // Instructions
                        if !exercise.instructions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Instructions")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 28, height: 28)
                                                .background(AppConstants.Colors.primary)
                                                .clipShape(Circle())
                                            
                                            Text(instruction)
                                                .font(.system(size: 16))
                                                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                                                .fixedSize(horizontal: false, vertical: true)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(AppConstants.Design.cornerRadius)
                            .padding(.horizontal, 20)
                        }
                        
                        // Timer for Timed Exercises
                        if exercise.isTimed {
                            timerCard
                                .padding(.horizontal, 20)
                        }
                        
                        // Description
                        if !exercise.description.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                                
                                Text(exercise.description)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .cornerRadius(AppConstants.Design.cornerRadius)
                            .padding(.horizontal, 20)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if let workout = workout {
                                Button(action: {
                                    showVideoPlayer = true
                                }) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                        Text("Start Exercise in Workout")
                                    }
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(AppConstants.Colors.primary)
                                    .cornerRadius(AppConstants.Design.cornerRadius)
                                }
                            }
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Done")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                                    .cornerRadius(AppConstants.Design.cornerRadius)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMedia()
                if exercise.isTimed, let duration = exercise.duration {
                    timerSeconds = duration
                }
            }
            .onDisappear {
                stopTimer()
                exerciseVideoPlayer?.pause()
                exerciseVideoPlayer = nil
            }
            .fullScreenCover(isPresented: $showVideoPlayer) {
                if let workout = workout {
                    VideoPlayerView(workout: workout)
                }
            }
        }
    }
    
    // MARK: - Timer Card
    
    private var timerCard: some View {
        VStack(spacing: 16) {
            Text("Exercise Timer")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Text(formatTimer(timerSeconds))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(AppConstants.Colors.primary)
                .monospacedDigit()
            
            HStack(spacing: 20) {
                Button(action: {
                    if isTimerRunning {
                        pauseTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Image(systemName: isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppConstants.Colors.primary)
                }
                
                Button(action: {
                    resetTimer()
                }) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                }
            }
        }
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerSeconds > 0 {
                timerSeconds -= 1
            } else {
                stopTimer()
                HapticFeedback.success()
            }
        }
    }
    
    private func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        if let duration = exercise.duration {
            timerSeconds = duration
        }
    }
    
    private func formatTimer(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    // MARK: - Animation / video loading
    
    /// `animationURL` may be Lottie JSON or a direct video URL (e.g. MP4 on R2).
    private func isDirectVideoURL(_ string: String) -> Bool {
        let lower = string.lowercased()
        let pathPart = lower.split(separator: "?").first.map(String.init) ?? lower
        let ext = [".mp4", ".webm", ".mov", ".m4v"]
        if ext.contains(where: { pathPart.hasSuffix($0) }) { return true }
        return ext.contains { lower.contains($0) }
    }
    
    private func loadMedia() {
        animationError = nil
        animationURL = nil
        exerciseVideoPlayer = nil
        
        guard let raw = exercise.animationURL?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            animationError = "No video or animation available"
            return
        }
        
        guard let url = URL(string: raw) else {
            animationError = "Invalid media URL"
            return
        }
        
        if isDirectVideoURL(raw) {
            exerciseVideoPlayer = AVPlayer(url: url)
        } else {
            animationURL = url
        }
    }
}

// MARK: - Lottie Animation View from URL

struct RemoteLottieAnimationView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        let animationView = LottieAnimationView()
        
        // Load animation from URL using Lottie's built-in method
        LottieAnimation.loadedFrom(url: url, session: URLSession.shared, closure: { animation in
            DispatchQueue.main.async {
                if let animation = animation {
                    animationView.animation = animation
                    animationView.contentMode = UIView.ContentMode.scaleAspectFit
                    animationView.loopMode = .loop
                    animationView.play()
                }
            }
        })
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

// MARK: - Flow Layout for Tags

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
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Exercise Detail Row

private struct ExerciseDetailRow: View {
    let icon: String
    let title: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
        }
    }
}

#Preview {
    ExerciseDetailView(
        exercise: Exercise(
            name: "Push-ups",
            description: "A classic upper body exercise",
            sets: 3,
            reps: 12,
            restTime: 30,
            muscleGroups: [.chest, .arms],
            difficultyLevel: .beginner,
            instructions: [
                "Start in plank position",
                "Lower your body until chest nearly touches floor",
                "Push back up to starting position",
                "Repeat for desired reps"
            ]
        ),
        workout: nil
    )
}

