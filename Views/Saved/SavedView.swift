import SwiftUI

private let savedBackground = Color(hex: "#F5F5F7")
private let savedCardWhite = Color.white
private let savedAccentOrange = Color(hex: "#FF9500")
private let savedTextPrimary = Color(hex: "#2A2A2A")
private let savedTextSecondary = Color(hex: "#8E8E93")

struct SavedView: View {
    @Environment(\.dismiss) var dismiss
    @State private var savedExercises: [String] = ["Lats Pull Down", "Seated Rowing", "Pullover"]
    @State private var savedVideos: [Workout] = []
    @State private var selectedWorkout: Workout?
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            savedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    exercisesSection
                    videosSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear saved") { }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(savedTextPrimary)
                    }
                }
            }
            .onAppear {
                loadSavedContent()
            }
            .fullScreenCover(item: $selectedWorkout) { workout in
                VideoPlayerView(workout: workout)
            }
        }
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(savedTextPrimary)
            
            VStack(spacing: 0) {
                ForEach(Array(savedExercises.enumerated()), id: \.offset) { index, name in
                    savedExerciseRow(title: name)
                    if index < savedExercises.count - 1 {
                        Rectangle()
                            .fill(savedTextSecondary.opacity(0.2))
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                
                Button("View all") {}
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(savedTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(savedCardWhite)
            }
            .background(savedCardWhite)
            .cornerRadius(12)
        }
    }
    
    private func savedExerciseRow(title: String) -> some View {
        Button {
            // Navigate to exercise detail if needed
        } label: {
            HStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(savedTextPrimary)
                Spacer()
                ZStack {
                    Circle()
                        .fill(savedAccentOrange)
                        .frame(width: 28, height: 28)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Videos Section
    
    private var videosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Videos")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(savedTextPrimary)
            
            if savedVideos.isEmpty {
                savedVideoPlaceholderCard(title: "Deadlifts", difficulty: .intermediate)
                savedVideoPlaceholderCard(title: "Standing Barbell Curls", difficulty: .beginner)
            } else {
                ForEach(savedVideos) { workout in
                    SavedVideoCard(workout: workout) {
                        selectedWorkout = workout
                    }
                }
            }
            
            Button("View all") {}
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(savedTextPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(savedCardWhite)
                .cornerRadius(12)
        }
    }
    
    private func savedVideoPlaceholderCard(title: String, difficulty: DifficultyLevel) -> some View {
        Button {
            // Placeholder tap
        } label: {
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#E5E5EA"),
                                Color(hex: "#C7C7CC")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.white.opacity(0.9))
                    )
                    .clipped()
                    .cornerRadius(12)
                
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(difficulty.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#34C759"))
                        .cornerRadius(6)
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func loadSavedContent() {
        guard let userId = authViewModel.currentUser?.id, !userId.isEmpty else {
            savedVideos = []
            return
        }
        Task {
            do {
                savedVideos = try await WorkoutService.shared.fetchUserWorkouts(userId: userId)
            } catch {
                savedVideos = []
            }
        }
    }
}

// MARK: - Saved Video Card (uses real Workout when available)

struct SavedVideoCard: View {
    let workout: Workout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let thumbnailURL = workout.thumbnailURL, !thumbnailURL.isEmpty {
                        AsyncImage(url: URL(string: thumbnailURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .empty, .failure:
                                Rectangle()
                                    .fill(Color(hex: "#E5E5EA"))
                            @unknown default:
                                Rectangle()
                                    .fill(Color(hex: "#E5E5EA"))
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppConstants.Colors.primary.opacity(0.6),
                                        AppConstants.Colors.secondary.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .frame(height: 180)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white.opacity(0.9))
                )
                .clipped()
                .cornerRadius(12)
                
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.difficulty.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: workout.difficulty.color))
                        .cornerRadius(6)
                    Text(workout.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        SavedView()
            .environmentObject(AuthViewModel())
    }
}
