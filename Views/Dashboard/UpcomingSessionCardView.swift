import SwiftUI

struct UpcomingSessionDisplay: Equatable {
    let title: String
    let durationMinutes: Int
    let intensity: String
    let target: String
}

struct UpcomingSessionCardView: View {
    let session: UpcomingSessionDisplay?
    let isFirstTimeUser: Bool
    let userName: String
    let onFilledCardTap: () -> Void
    let onCreateTap: () -> Void
    let onStartFirstWorkoutTap: () -> Void

    var body: some View {
        Group {
            if isFirstTimeUser && session == nil {
                cardContent
            } else {
                Button(action: {
                    if session != nil {
                        onFilledCardTap()
                    } else {
                        onCreateTap()
                    }
                }) {
                    cardContent
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel(
            session.map { "Upcoming session: \($0.title)" } ?? (isFirstTimeUser ? "Start your first workout" : "Create your next workout session")
        )
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let session {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.55, green: 0.82, blue: 1.0))
                    Text("UPCOMING SESSION")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)

                Text(session.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                sessionDetailRow(session: session)
            } else if isFirstTimeUser {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hey \(userName)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                    Text("Let’s get your first workout started")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    Button(action: onStartFirstWorkoutTap) {
                        HStack(spacing: 10) {
                            Text("Start your first workout")
                                .font(.system(size: 16, weight: .bold))
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22, weight: .regular))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppConstants.TrakkitHome.accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: AppConstants.TrakkitHome.accentOrange.opacity(0.28), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)

                    Button(action: onCreateTap) {
                        Text("Create custom workout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.TrakkitHome.heading)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#E8E8ED"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.55, green: 0.82, blue: 1.0))
                    Text("UPCOMING SESSION")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
                .fixedSize(horizontal: true, vertical: false)

                Text("Plan your next session")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Create a workout to see it here.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                Text("Create workout")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppConstants.TrakkitHome.accentOrange)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: isFirstTimeUser && session == nil ? 220 : (session == nil ? 160 : 180))
        .background {
            if session != nil || !isFirstTimeUser {
                upcomingSessionGradientBackground
            } else {
                Color.white
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous))
        .shadow(
            color: AppConstants.TrakkitHome.cardShadowColor,
            radius: AppConstants.TrakkitHome.cardShadowRadius,
            x: 0,
            y: AppConstants.TrakkitHome.cardShadowY
        )
    }

    private var upcomingSessionGradientBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppConstants.TrakkitHome.upcomingCardGradientLeading,
                    AppConstants.TrakkitHome.upcomingCardGradientTrailing
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            Image("upcominsessionbgimg")
                .resizable()
                .scaledToFill()
                .opacity(0.38)
        }
    }

    private func sessionDetailRow(session: UpcomingSessionDisplay) -> some View {
        HStack(alignment: .center, spacing: 0) {
            detailColumn(title: "Duration", value: "\(session.durationMinutes) mins")
            sessionColumnDivider
            detailColumn(title: "Intensity", value: session.intensity)
            sessionColumnDivider
            detailColumn(title: "Target", value: session.target)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Vertical rule between columns — full row height, line centered in a fixed gutter so text balances on both sides.
    private var sessionColumnDivider: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.42))
                .frame(width: 1)
        }
        .frame(maxHeight: .infinity)
        .frame(width: 20)
    }

    private func detailColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 16) {
        UpcomingSessionCardView(
            session: UpcomingSessionDisplay(
                title: "Back & Biceps",
                durationMinutes: 75,
                intensity: "High",
                target: "Hypertrophy"
            ),
            isFirstTimeUser: false,
            userName: "Rohan",
            onFilledCardTap: {},
            onCreateTap: {},
            onStartFirstWorkoutTap: {}
        )
        UpcomingSessionCardView(
            session: nil,
            isFirstTimeUser: true,
            userName: "Rohan",
            onFilledCardTap: {},
            onCreateTap: {},
            onStartFirstWorkoutTap: {}
        )
    }
    .padding()
    .background(AppConstants.TrakkitHome.background)
}
