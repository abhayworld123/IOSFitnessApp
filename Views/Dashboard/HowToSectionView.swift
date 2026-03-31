import SwiftUI

struct HowToSectionView: View {
    let exercises: [Exercise]
    let onExerciseTap: (Exercise) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(exercises) { exercise in
                        HowToExerciseCard(exercise: exercise) {
                            onExerciseTap(exercise)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct HowToExerciseCard: View {
    let exercise: Exercise
    let onTap: () -> Void

    private var placeholderGradient: some View {
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

    private var thumbnailLayer: some View {
        Group {
            if let s = exercise.thumbnailURL?.trimmingCharacters(in: .whitespacesAndNewlines),
               !s.isEmpty,
               let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderGradient
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderGradient
                    @unknown default:
                        placeholderGradient
                    }
                }
            } else {
                placeholderGradient
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topLeading) {
                thumbnailLayer
                
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
                        Text(exercise.difficultyLevel.displayName)
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
            .clipped()
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(exercise.name)
        .accessibilityHint("Opens exercise details")
    }
}

#Preview {
    HowToSectionView(
        exercises: [],
        onExerciseTap: { _ in }
    )
    .background(Color(hex: "#F5F5F7"))
    .previewLayout(.sizeThatFits)
}
