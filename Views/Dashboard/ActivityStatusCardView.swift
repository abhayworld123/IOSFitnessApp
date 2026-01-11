import SwiftUI

struct ActivityStatusCardView: View {
    let activity: ActivityStatus
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.system(size: 20))
                    .foregroundColor(AppConstants.Colors.primary)
                
                Text("Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
            }
            
            // Steps
            ActivityMetricRow(
                icon: "figure.walk",
                title: "Steps",
                current: activity.steps,
                goal: activity.stepsGoal,
                progress: activity.stepsProgress,
                colorScheme: colorScheme
            )
            
            // Active Minutes
            ActivityMetricRow(
                icon: "clock.fill",
                title: "Active Minutes",
                current: activity.activeMinutes,
                goal: activity.activeMinutesGoal,
                progress: activity.activeMinutesProgress,
                colorScheme: colorScheme
            )
            
            // Calories Burned
            ActivityMetricRow(
                icon: "flame.fill",
                title: "Calories Burned",
                current: activity.caloriesBurned,
                goal: activity.caloriesBurnedGoal,
                progress: activity.caloriesBurnedProgress,
                colorScheme: colorScheme
            )
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ActivityMetricRow: View {
    let icon: String
    let title: String
    let current: Int
    let goal: Int
    let progress: Double
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.primary)
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                
                Spacer()
                
                Text("\(current) / \(goal)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppConstants.Colors.primary)
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    ActivityStatusCardView(
        activity: ActivityStatus(
            steps: 8245,
            stepsGoal: 10000,
            activeMinutes: 45,
            activeMinutesGoal: 60,
            caloriesBurned: 350,
            caloriesBurnedGoal: 500
        )
    )
    .padding()
    .background(AppConstants.Colors.background(colorScheme: .dark))
}

