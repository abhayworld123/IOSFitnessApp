import SwiftUI

struct HowToSectionView: View {
    let exercises: [Exercise]
    let onExerciseTap: (Exercise) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How to")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.TrakkitHome.heading)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
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

    private var difficultyLabel: String {
        switch exercise.difficultyLevel {
        case .beginner:
            return "Easy"
        default:
            return exercise.difficultyLevel.displayName
        }
    }

    private var badgeColor: Color {
        Color(hex: exercise.difficultyLevel.color)
    }

    private var placeholderGradient: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        AppConstants.TrakkitHome.upcomingGradientStart,
                        AppConstants.TrakkitHome.upcomingGradientEnd
                    ],
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

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack {
                    HStack {
                        Text(difficultyLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(badgeColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Spacer()
                    }
                    .padding(14)

                    Spacer()

                    HStack(alignment: .bottom) {
                        Text(exercise.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        if exercise.hasPlayableMedia {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(14)
                }
            }
            .frame(width: 260, height: 150)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(
                color: AppConstants.TrakkitHome.cardShadowColor,
                radius: AppConstants.TrakkitHome.cardShadowRadius,
                x: 0,
                y: AppConstants.TrakkitHome.cardShadowY
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(exercise.name)
        .accessibilityHint(exercise.hasPlayableMedia ? "Play exercise video" : "Opens exercise details")
    }
}

#Preview {
    HowToSectionView(
        exercises: [],
        onExerciseTap: { _ in }
    )
    .background(AppConstants.TrakkitHome.background)
    .previewLayout(.sizeThatFits)
}
