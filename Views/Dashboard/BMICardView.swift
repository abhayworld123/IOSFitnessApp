import SwiftUI

struct BMICardView: View {
    let bmi: BMIData
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 20))
                    .foregroundColor(AppConstants.Colors.primary)
                
                Text("BMI")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", bmi.value))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Text(bmi.status.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: bmi.status.color))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: bmi.status.color).opacity(0.15))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Height")
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    Text("\(Int(bmi.height)) cm")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weight")
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    Text("\(Int(bmi.weight)) kg")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                }
            }
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    BMICardView(bmi: BMIData(height: 175, weight: 70))
        .padding()
        .background(AppConstants.Colors.background(colorScheme: .dark))
}

