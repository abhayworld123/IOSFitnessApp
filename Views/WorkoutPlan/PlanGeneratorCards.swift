import SwiftUI

// MARK: - Selection Cards

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.primary)
                
                Text(goal.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadius)
                    .stroke(isSelected ? Color.clear : AppConstants.Colors.textSecondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct LevelCard: View {
    let level: DifficultyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(level.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct DaysCard: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text("\(days)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.primary)
                
                Text("days")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppConstants.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct DurationCard: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text("\(minutes)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.primary)
                
                Text("minutes")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppConstants.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct EquipmentCard: View {
    let equipment: EquipmentAvailability
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(equipment.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct PlanInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(AppConstants.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.Colors.textPrimary)
        }
    }
}
