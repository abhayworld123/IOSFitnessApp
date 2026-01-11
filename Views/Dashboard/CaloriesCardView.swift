import SwiftUI

struct CaloriesCardView: View {
    let calories: CalorieData
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppConstants.Colors.primary)
                
                Text("Calories")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
            }
            
            // Net Calories
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(calories.net)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(calories.net >= 0 ? AppConstants.Colors.textPrimary(colorScheme: colorScheme) : AppConstants.Colors.success)
                
                Text("net")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            
            // Breakdown
            VStack(spacing: 10) {
                CalorieRow(
                    label: "Consumed",
                    value: calories.consumed,
                    color: AppConstants.Colors.primary,
                    colorScheme: colorScheme
                )
                
                CalorieRow(
                    label: "Burned",
                    value: calories.burned,
                    color: AppConstants.Colors.success,
                    colorScheme: colorScheme
                )
                
                Divider()
                    .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3))
                
                HStack {
                    Text("Target")
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Text("\(calories.target) cal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                }
                
                if calories.remaining > 0 {
                    HStack {
                        Text("Remaining")
                            .font(.system(size: 13))
                            .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        
                        Spacer()
                        
                        Text("\(calories.remaining) cal")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppConstants.Colors.primary)
                    }
                }
            }
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct CalorieRow: View {
    let label: String
    let value: Int
    let color: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            
            Spacer()
            
            Text("\(value) cal")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

#Preview {
    CaloriesCardView(
        calories: CalorieData(
            consumed: 1850,
            burned: 350,
            target: 2000
        )
    )
    .padding()
    .background(AppConstants.Colors.background(colorScheme: .dark))
}

