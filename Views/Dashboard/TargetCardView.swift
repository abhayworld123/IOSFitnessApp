import SwiftUI

struct TargetCardView: View {
    let target: FitnessTarget
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: target.goal.icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppConstants.Colors.primary)
                
                Text("Target")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Spacer()
            }
            
            Text(target.goal.displayName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            if let targetWeight = target.targetWeight {
                Text("Target: \(Int(targetWeight)) kg")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    
                    Spacer()
                    
                    Text("\(Int(target.currentProgress))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppConstants.Colors.primary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppConstants.Colors.primary,
                                        AppConstants.Colors.secondary
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (target.currentProgress / 100), height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    TargetCardView(
        target: FitnessTarget(
            goal: .weightLoss,
            targetWeight: 65,
            targetDate: Date(),
            currentProgress: 45
        )
    )
    .padding()
    .background(AppConstants.Colors.background(colorScheme: .dark))
}

