import SwiftUI

struct NotificationsView: View {
    @ObservedObject var viewModel: NotificationViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    init(viewModel: NotificationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    loadingView
                } else if let loadErr = viewModel.listLoadError, viewModel.notifications.isEmpty {
                    LoadFailureFallbackView(
                        message: loadErr,
                        onRetry: { Task { await viewModel.fetchNotifications() } },
                        onGoBack: { dismiss() }
                    )
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.unreadCount > 0 {
                        Button("Mark All Read") {
                            Task {
                                await viewModel.markAllAsRead()
                            }
                        }
                        .font(.system(size: 14))
                    }
                }
            }
            .refreshable {
                await viewModel.fetchNotifications()
            }
            .onAppear {
                viewModel.startListening()
                Task {
                    await viewModel.fetchNotifications()
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
    
    // MARK: - Notifications List
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.sortedGroups, id: \.self) { group in
                    if let groupNotifications = viewModel.groupedNotifications[group] {
                        Section {
                            ForEach(groupNotifications) { notification in
                                NotificationRowView(
                                    notification: notification,
                                    colorScheme: colorScheme
                                ) {
                                    Task {
                                        await viewModel.markAsRead(notification)
                                        NotificationDeepLink.post(actionURL: notification.actionURL)
                                    }
                                } onDelete: {
                                    Task {
                                        await viewModel.deleteNotification(notification)
                                    }
                                }
                                
                                if notification.id != groupNotifications.last?.id {
                                    Divider()
                                        .background(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.2))
                                        .padding(.leading, 72)
                                }
                            }
                        } header: {
                            HStack {
                                Text(group)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                                    .textCase(.none)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(AppConstants.Colors.background(colorScheme: colorScheme))
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.5))
            
            Text("No Notifications")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Text("You're all caught up! Check back later for updates.")
                .font(.system(size: 14))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading notifications...")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
        }
    }
}

// MARK: - Notification Row View

struct NotificationRowView: View {
    let notification: Notification
    let colorScheme: ColorScheme
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: notification.type.color).opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: notification.type.color))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(notification.title)
                            .font(.system(size: 15, weight: notification.isRead ? .medium : .semibold))
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Unread indicator
                        if !notification.isRead {
                            Circle()
                                .fill(Color(hex: notification.type.color))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    Text(notification.message)
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        .lineLimit(2)
                    
                    Text(relativeTimeString(from: notification.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.7))
                        .padding(.top, 2)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                notification.isRead ?
                AppConstants.Colors.cardBackground(colorScheme: colorScheme) :
                AppConstants.Colors.cardBackground(colorScheme: colorScheme).opacity(0.7)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            if !notification.isRead {
                Button {
                    onTap()
                } label: {
                    Label("Mark Read", systemImage: "checkmark.circle")
                }
                .tint(.blue)
            }
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NotificationsView(viewModel: NotificationViewModel())
}

