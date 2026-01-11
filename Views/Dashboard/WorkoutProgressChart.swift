import SwiftUI
import Charts

@available(iOS 16.0, *)
struct WorkoutProgressChart: View {
    let weeklyData: [DailyWorkoutData]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Chart {
            ForEach(weeklyData) { data in
                BarMark(
                    x: .value("Day", dayLabel(for: data.date)),
                    y: .value("Workouts", data.workoutsCompleted)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppConstants.Colors.primary,
                            AppConstants.Colors.secondary
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    .font(.system(size: 11))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    .font(.system(size: 11))
                AxisGridLine()
                    .foregroundStyle(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.2))
            }
        }
        .frame(height: 200)
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// Fallback for iOS < 16
struct WorkoutProgressChartFallback: View {
    let weeklyData: [DailyWorkoutData]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            let maxValue = max(weeklyData.map { $0.workoutsCompleted }.max() ?? 1, 1)
            let barWidth = (geometry.size.width - CGFloat(weeklyData.count - 1) * 8) / CGFloat(weeklyData.count)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(weeklyData) { data in
                    VStack(spacing: 4) {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppConstants.Colors.primary,
                                        AppConstants.Colors.secondary
                                    ]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(
                                width: barWidth,
                                height: max(geometry.size.height * CGFloat(data.workoutsCompleted) / CGFloat(maxValue), 4)
                            )
                        
                        Text(dayLabel(for: data.date))
                            .font(.system(size: 10))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    }
                }
            }
        }
        .frame(height: 200)
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// Wrapper that chooses the right chart based on iOS version
struct WorkoutProgressChartWrapper: View {
    let weeklyData: [DailyWorkoutData]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            WorkoutProgressChart(weeklyData: weeklyData)
        } else {
            WorkoutProgressChartFallback(weeklyData: weeklyData)
        }
    }
}

