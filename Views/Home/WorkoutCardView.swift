import SwiftUI

struct WorkoutCardView: View {
    let workout: Workout
    let isPremium: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail Image
                ZStack(alignment: .topTrailing) {
                    if let thumbnailURL = workout.thumbnailURL, !thumbnailURL.isEmpty {
                        AsyncImage(url: URL(string: thumbnailURL)) { phase in
                            switch phase {
                            case .empty:
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
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
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
                            @unknown default:
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
                        .clipped()
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
                            .frame(height: 180)
                    }
                    
                    // Play Icon Overlay
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "play.fill")
                                .foregroundColor(AppConstants.Colors.primary)
                                .font(.system(size: 20))
                        )
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    // Premium Badge
                    if workout.isPremium && !isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(AppConstants.Colors.primary)
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            }
                            Spacer()
                        }
                        .padding(12)
                    }
                    
                    // Difficulty Badge
                    VStack {
                        HStack {
                            Text(workout.difficulty.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: workout.difficulty.color).opacity(0.9))
                                .cornerRadius(12)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Category Tag
                    HStack {
                        Image(systemName: workout.category.icon)
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.Colors.primary)
                        Text(workout.category.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    }
                    
                    // Title
                    Text(workout.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Description
                    Text(workout.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Duration and Calories
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.Colors.primary)
                            Text("\(workout.duration) min")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.Colors.primary)
                            Text("\(workout.caloriesBurned) cal")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        }
                        
                        Spacer()
                    }
                }
                .padding(16)
            }
            .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
            .cornerRadius(AppConstants.Design.cornerRadius)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    WorkoutCardView(
        workout: Workout(
            title: "Full Body HIIT",
            description: "High-intensity interval training that targets your entire body.",
            category: .hiit,
            difficulty: .intermediate,
            duration: 30,
            isPremium: true,
            caloriesBurned: 350
        ),
        isPremium: false,
        onTap: {}
    )
    .padding()
    .background(AppConstants.Colors.background(colorScheme: .dark))
}

