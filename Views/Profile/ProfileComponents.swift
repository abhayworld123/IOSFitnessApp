import SwiftUI

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
}

struct RecentWorkoutRow: View {
    let item: WorkoutHistoryItem
    @State private var workout: Workout?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumbnailURL = item.workout.thumbnailURL, !thumbnailURL.isEmpty {
                AsyncImage(url: URL(string: thumbnailURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .frame(width: 60, height: 60)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .frame(width: 60, height: 60)
                    @unknown default:
                        Rectangle()
                            .fill(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                            .frame(width: 60, height: 60)
                    }
                }
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppConstants.Colors.primary,
                                AppConstants.Colors.secondary
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.workout.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    .lineLimit(1)
                Text(formatDate(item.completedDate))
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            .padding()
        }
    }
}

struct ThemeToggleRow: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "paintbrush.fill")
                .font(.system(size: 20))
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 24)
            Text("Theme")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            Spacer()
            Picker("Theme", selection: $themeManager.currentTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.menu)
            .tint(AppConstants.Colors.primary)
        }
        .padding()
    }
}
