import SwiftUI

struct WaterIntakeCardView: View {
    let waterIntake: WaterIntake
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color.blue)
                
                Text("Water Intake")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
            }
            
            // Circular Progress - Centered at top
            HStack {
                Spacer()
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(
                            AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.15),
                            lineWidth: 14
                        )
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: waterIntake.progress)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: waterIntake.progress)
                    
                    // Percentage text in center
                    Text("\(Int(waterIntake.progress * 100))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                }
                .frame(width: 100, height: 100)
                Spacer()
            }
            
            // Text details - Below the progress circle
            VStack(spacing: 10) {
                // Current amount
                HStack {
                    Text("Current")
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Text("\(formatNumber(waterIntake.current)) ml")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.blue)
                }
                
                HStack {
                    Text("Target")
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Text("\(formatNumber(waterIntake.target)) ml")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                }
                
                if waterIntake.remaining > 0 {
                    Divider()
                        .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                    
                    HStack {
                        Text("Remaining")
                            .font(.system(size: 13))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        
                        Spacer()
                        
                        Text("\(formatNumber(waterIntake.remaining)) ml")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.blue)
                    }
                } else {
                    Divider()
                        .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                    
                    HStack {
                        Text("Status")
                            .font(.system(size: 13))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        
                        Spacer()
                        
                        Text("Goal achieved! 🎉")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.success)
                    }
                }
            }
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

#Preview {
    WaterIntakeCardView(
        waterIntake: WaterIntake(current: 1500, target: 2000)
    )
    .padding()
    .background(AppConstants.Colors.background(colorScheme: .dark))
}

