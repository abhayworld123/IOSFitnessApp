import SwiftUI

struct WorkoutProgressCardView: View {
    let progress: WorkoutProgress
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppConstants.Colors.primary)
                
                Text("Workout Progress")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
            }
            
            // Stats Row
            HStack(spacing: 20) {
                StatItem(
                    value: "\(progress.totalWorkouts)",
                    label: "Total",
                    colorScheme: colorScheme
                )
                
                StatItem(
                    value: String(format: "%.1f", progress.averageWorkoutsPerDay),
                    label: "Avg/Day",
                    colorScheme: colorScheme
                )
                
                Spacer()
            }
            
            // Chart
            WorkoutProgressChartWrapper(weeklyData: progress.weeklyData)
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
    }
}

#Preview {
    let calendar = Calendar.current
    var weeklyData: [DailyWorkoutData] = []
    
    for i in 0..<7 {
        let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
        weeklyData.append(DailyWorkoutData(
            date: date,
            workoutsCompleted: Int.random(in: 0...2),
            duration: 30,
            caloriesBurned: 200
        ))
    }
    weeklyData.reverse()
    
    return WorkoutProgressCardView(
        progress: WorkoutProgress(weeklyData: weeklyData)
    )
    .padding()
    .background(AppConstants.Colors.background(colorScheme: .dark))
}

