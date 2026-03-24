import SwiftUI

struct HowToSectionView: View {
    let workouts: [Workout]
    let onWorkoutTap: (Workout) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(workouts) { workout in
                        HowToWorkoutCard(workout: workout) {
                            onWorkoutTap(workout)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct HowToWorkoutCard: View {
    let workout: Workout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                // Thumbnail
                if let thumbnailURL = workout.thumbnailURL, !thumbnailURL.isEmpty {
                    AsyncImage(url: URL(string: thumbnailURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(hex: "#E5E5EA"))
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
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
                                    AppConstants.Colors.primary,
                                    AppConstants.Colors.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
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
                        Text(workout.difficulty.rawValue.capitalized)
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
                        Text(workout.title)
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
}

#Preview {
    HowToSectionView(
        workouts: [],
        onWorkoutTap: { _ in }
    )
    .background(Color(hex: "#F5F5F7"))
    .previewLayout(.sizeThatFits)
}
