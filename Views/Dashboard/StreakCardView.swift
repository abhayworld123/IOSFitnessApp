import SwiftUI

struct StreakCardView: View {
    let streakData: StreakData
    let onViewCalendar: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header - Outside the card
            HStack {
                Text("Your Streak")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                Spacer()
                
                Button(action: onViewCalendar) {
                    Text("View Calendar")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#FF9500"))
                }
                .accessibilityLabel("View workout streak calendar")
            }
            .padding(.horizontal, 20)
            
            // Streak Card - White card with content
            HStack(spacing: 16) {
                // Fire Icon with "Weeks"
                VStack(spacing: 4) {
                    FlameIconView()
                        .frame(width: 24, height: 32)
                    
                    Text("Weeks")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                .frame(width: 60)
                
                // Week Days
                HStack(spacing: 8) {
                    ForEach(streakData.weeklyActivities) { day in
                        VStack(spacing: 8) {
                            Text(day.dayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#8E8E93"))
                            
                            ZStack {
                                Circle()
                                    .fill(day.isCompleted ? Color(hex: "#34C759") : Color(hex: "#E5E5EA"))
                                    .frame(width: 28, height: 28)
                                
                                if day.isCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Flame Icon View

struct FlameIconView: View {
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 24.0
            let scaleY = geometry.size.height / 32.0
            
            Path { path in
                // Start point: M9 1.50256
                path.move(to: CGPoint(x: 9 * scaleX, y: 1.50256 * scaleY))
                
                // First cubic bezier: C9 0.182557 10.584 -0.493943 11.538 0.419557
                path.addCurve(
                    to: CGPoint(x: 11.538 * scaleX, y: 0.419557 * scaleY),
                    control1: CGPoint(x: 9 * scaleX, y: 0.182557 * scaleY),
                    control2: CGPoint(x: 10.584 * scaleX, y: -0.493943 * scaleY)
                )
                
                // Second cubic bezier: C14.475 3.23356 16.182 9.41206 14.163 14.0996
                path.addCurve(
                    to: CGPoint(x: 14.163 * scaleX, y: 14.0996 * scaleY),
                    control1: CGPoint(x: 14.475 * scaleX, y: 3.23356 * scaleY),
                    control2: CGPoint(x: 16.182 * scaleX, y: 9.41206 * scaleY)
                )
                
                // Line: L14.043 14.3606
                path.addLine(to: CGPoint(x: 14.043 * scaleX, y: 14.3606 * scaleY))
                
                // Line: L14.061 14.3651
                path.addLine(to: CGPoint(x: 14.061 * scaleX, y: 14.3651 * scaleY))
                
                // Cubic bezier: C14.9985 14.5646 15.8655 13.7201 17.5155 11.1056
                path.addCurve(
                    to: CGPoint(x: 17.5155 * scaleX, y: 11.1056 * scaleY),
                    control1: CGPoint(x: 14.9985 * scaleX, y: 14.5646 * scaleY),
                    control2: CGPoint(x: 15.8655 * scaleX, y: 13.7201 * scaleY)
                )
                
                // Line: L17.7255 10.7696
                path.addLine(to: CGPoint(x: 17.7255 * scaleX, y: 10.7696 * scaleY))
                
                // Multiple cubic beziers for the curve
                // C17.8472 10.5736 18.0125 10.4084 18.2084 10.2868
                path.addCurve(
                    to: CGPoint(x: 18.2084 * scaleX, y: 10.2868 * scaleY),
                    control1: CGPoint(x: 17.8472 * scaleX, y: 10.5736 * scaleY),
                    control2: CGPoint(x: 18.0125 * scaleX, y: 10.4084 * scaleY)
                )
                
                // C18.4043 10.1651 18.6257 10.0903 18.8553 10.0681
                path.addCurve(
                    to: CGPoint(x: 18.8553 * scaleX, y: 10.0681 * scaleY),
                    control1: CGPoint(x: 18.4043 * scaleX, y: 10.1651 * scaleY),
                    control2: CGPoint(x: 18.6257 * scaleX, y: 10.0903 * scaleY)
                )
                
                // C19.0848 10.0459 19.3164 10.0769 19.532 10.1588
                path.addCurve(
                    to: CGPoint(x: 19.532 * scaleX, y: 10.1588 * scaleY),
                    control1: CGPoint(x: 19.0848 * scaleX, y: 10.0459 * scaleY),
                    control2: CGPoint(x: 19.3164 * scaleX, y: 10.0769 * scaleY)
                )
                
                // C19.7477 10.2406 19.9415 10.3711 20.0985 10.5401
                path.addCurve(
                    to: CGPoint(x: 20.0985 * scaleX, y: 10.5401 * scaleY),
                    control1: CGPoint(x: 19.7477 * scaleX, y: 10.2406 * scaleY),
                    control2: CGPoint(x: 19.9415 * scaleX, y: 10.3711 * scaleY)
                )
                
                // C22.0995 12.6926 24 17.1056 24 19.9451
                path.addCurve(
                    to: CGPoint(x: 24 * scaleX, y: 19.9451 * scaleY),
                    control1: CGPoint(x: 22.0995 * scaleX, y: 12.6926 * scaleY),
                    control2: CGPoint(x: 24 * scaleX, y: 17.1056 * scaleY)
                )
                
                // C24 26.3426 18.6135 31.5026 12 31.5026
                path.addCurve(
                    to: CGPoint(x: 12 * scaleX, y: 31.5026 * scaleY),
                    control1: CGPoint(x: 24 * scaleX, y: 26.3426 * scaleY),
                    control2: CGPoint(x: 18.6135 * scaleX, y: 31.5026 * scaleY)
                )
                
                // C5.3865 31.5026 0 26.3426 0 19.9436
                path.addCurve(
                    to: CGPoint(x: 0 * scaleX, y: 19.9436 * scaleY),
                    control1: CGPoint(x: 5.3865 * scaleX, y: 31.5026 * scaleY),
                    control2: CGPoint(x: 0 * scaleX, y: 26.3426 * scaleY)
                )
                
                // C0 16.5656 1.533 12.8696 3.948 10.4921
                path.addCurve(
                    to: CGPoint(x: 3.948 * scaleX, y: 10.4921 * scaleY),
                    control1: CGPoint(x: 0 * scaleX, y: 16.5656 * scaleY),
                    control2: CGPoint(x: 1.533 * scaleX, y: 12.8696 * scaleY)
                )
                
                // L4.8555 9.60856
                path.addLine(to: CGPoint(x: 4.8555 * scaleX, y: 9.60856 * scaleY))
                
                // C5.217 9.25456 5.5065 8.96356 5.7825 8.67256
                path.addCurve(
                    to: CGPoint(x: 5.7825 * scaleX, y: 8.67256 * scaleY),
                    control1: CGPoint(x: 5.217 * scaleX, y: 9.25456 * scaleY),
                    control2: CGPoint(x: 5.5065 * scaleX, y: 8.96356 * scaleY)
                )
                
                // C7.9275 6.40456 9 4.28656 9 1.50256
                path.addCurve(
                    to: CGPoint(x: 9 * scaleX, y: 1.50256 * scaleY),
                    control1: CGPoint(x: 7.9275 * scaleX, y: 6.40456 * scaleY),
                    control2: CGPoint(x: 9 * scaleX, y: 4.28656 * scaleY)
                )
                
                // Close path: Z
                path.closeSubpath()
            }
            .fill(Color(hex: "#EC8F37"))
        }
    }
}

#Preview {
    StreakCardView(
        streakData: DashboardViewModel2.generateMockStreakData(),
        onViewCalendar: {}
    )
    .background(Color(hex: "#F5F5F7"))
    .previewLayout(.sizeThatFits)
}
