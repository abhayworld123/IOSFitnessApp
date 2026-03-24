import SwiftUI

struct DailyTrackerCardView: View {
    let dailyMetrics: DailyMetrics
    let onWeightTap: (() -> Void)?
    let onWaterTap: (() -> Void)?
    let onStepsTap: (() -> Void)?
    
    init(
        dailyMetrics: DailyMetrics,
        onWeightTap: (() -> Void)? = nil,
        onWaterTap: (() -> Void)? = nil,
        onStepsTap: (() -> Void)? = nil
    ) {
        self.dailyMetrics = dailyMetrics
        self.onWeightTap = onWeightTap
        self.onWaterTap = onWaterTap
        self.onStepsTap = onStepsTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Tracker")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            VStack(spacing: 20) {
                // Weight
                Button(action: {
                    onWeightTap?()
                }) {
                    TrackerItemRow(
                        icon: "scalemass",
                        iconColor: Color(hex: "#FF9500"),
                        title: "Weight",
                        value: dailyMetrics.weight.displayText
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Water
                Button(action: {
                    onWaterTap?()
                }) {
                    TrackerItemRow(
                        icon: "drop",
                        iconColor: Color(hex: "#007AFF"),
                        title: "Water",
                        value: dailyMetrics.water.displayText
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Sleep
                TrackerItemRow(
                    icon: "moon",
                    iconColor: Color(hex: "#AF52DE"),
                    title: "Sleep",
                    value: dailyMetrics.sleep.displayText
                )
                
                // Steps
                Button(action: {
                    onStepsTap?()
                }) {
                    TrackerItemRow(
                        icon: "figure.walk",
                        iconColor: Color(hex: "#34C759"),
                        title: "Steps",
                        value: dailyMetrics.steps.displayText
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

struct TrackerItemRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                Text(value)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
            
            Spacer()
        }
    }
}

#Preview {
    DailyTrackerCardView(
        dailyMetrics: DashboardViewModel2.generateMockDailyMetrics()
    )
    .background(Color(hex: "#F5F5F7"))
    .previewLayout(.sizeThatFits)
}
