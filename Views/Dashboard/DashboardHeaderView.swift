import SwiftUI

struct DashboardHeaderView: View {
    let userName: String
    let profileImageURL: String?
    let unreadNotificationCount: Int
    /// When true, shows “Welcome” (caption) + bold name (first-time home).
    var useWelcomeGreeting: Bool = false
    let onSearchTap: () -> Void
    let onNotificationsTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let urlString = profileImageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !urlString.isEmpty,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            letterAvatar
                        @unknown default:
                            letterAvatar
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    letterAvatar
                }
            }

            Group {
                if useWelcomeGreeting {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Welcome")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                        Text(userName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppConstants.TrakkitHome.heading)
                            .lineLimit(1)
                    }
                } else {
                    Text("Hello, \(userName)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            Button(action: onSearchTap) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
            }
            .accessibilityLabel("Search exercises")

            Button(action: onNotificationsTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppConstants.TrakkitHome.heading)

                    if unreadNotificationCount > 0 {
                        Text(min(unreadNotificationCount, 99), format: .number)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, unreadNotificationCount > 9 ? 4 : 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
            }
            .accessibilityLabel("Notifications")
            .accessibilityValue(unreadNotificationCount > 0 ? "\(unreadNotificationCount) unread" : "No unread notifications")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var letterAvatar: some View {
        Circle()
            .fill(AppConstants.Colors.primary.opacity(0.2))
            .frame(width: 50, height: 50)
            .overlay(
                Text(String(userName.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.primary)
            )
    }
}

#Preview("Welcome") {
    DashboardHeaderView(
        userName: "Rohan",
        profileImageURL: nil,
        unreadNotificationCount: 4,
        useWelcomeGreeting: true,
        onSearchTap: {},
        onNotificationsTap: {}
    )
    .background(AppConstants.TrakkitHome.background)
}

#Preview("Hello") {
    DashboardHeaderView(
        userName: "Rohan",
        profileImageURL: nil,
        unreadNotificationCount: 4,
        onSearchTap: {},
        onNotificationsTap: {}
    )
    .background(AppConstants.TrakkitHome.background)
}
