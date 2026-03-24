import SwiftUI
import Charts

private let profileChartOrange = Color(hex: "#FF9500")

@available(iOS 16.0, *)
struct ProfileActivityChart: View {
    let monthlyData: [DailyWorkoutData]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Chart {
            ForEach(monthlyData) { data in
                LineMark(
                    x: .value("Date", data.date),
                    y: .value("Workouts", data.workoutsCompleted)
                )
                .foregroundStyle(profileChartOrange)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color(hex: "#8E8E93"))
                    .font(.system(size: 10))
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .foregroundStyle(Color(hex: "#8E8E93"))
                    .font(.system(size: 10))
                AxisGridLine()
                    .foregroundStyle(Color(hex: "#8E8E93").opacity(0.2))
            }
        }
        .frame(height: 180)
    }
}

struct ProfileActivityChartFallback: View {
    let monthlyData: [DailyWorkoutData]
    @Environment(\.colorScheme) var colorScheme
    
    private let chartOrange = Color(hex: "#FF9500")
    
    var body: some View {
        GeometryReader { geometry in
            let maxVal = max(monthlyData.map { $0.workoutsCompleted }.max() ?? 1, 1)
            let step = monthlyData.isEmpty ? 0 : (geometry.size.width - 40) / max(CGFloat(monthlyData.count - 1), 1)
            ZStack(alignment: .bottomLeading) {
                Path { path in
                    guard monthlyData.count > 1 else { return }
                    let height = geometry.size.height - 24
                    for (i, data) in monthlyData.enumerated() {
                        let x = 20 + CGFloat(i) * step
                        let y = height - (CGFloat(data.workoutsCompleted) / CGFloat(maxVal)) * height
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(chartOrange, lineWidth: 2)
            }
        }
        .frame(height: 180)
    }
}

struct ProfileActivityChartWrapper: View {
    let monthlyData: [DailyWorkoutData]
    
    var body: some View {
        if #available(iOS 16.0, *) {
            ProfileActivityChart(monthlyData: monthlyData)
        } else {
            ProfileActivityChartFallback(monthlyData: monthlyData)
        }
    }
}
