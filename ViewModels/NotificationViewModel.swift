import Foundation
import SwiftUI

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let notificationService = NotificationService.shared
    private let authService = AuthService.shared
    
    // MARK: - Grouped Notifications
    
    var groupedNotifications: [String: [Notification]] {
        Dictionary(grouping: notifications) { $0.dateGroup }
    }
    
    var sortedGroups: [String] {
        let groups = Array(groupedNotifications.keys)
        let order = ["Today", "Yesterday", "This Week"]
        
        return groups.sorted { group1, group2 in
            let index1 = order.firstIndex(of: group1) ?? Int.max
            let index2 = order.firstIndex(of: group2) ?? Int.max
            
            if index1 != index2 {
                return index1 < index2
            }
            
            // If both are not in the predefined order, sort by date
            return group1 < group2
        }
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Fetch Notifications
    
    func fetchNotifications() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            notifications = try await notificationService.fetchNotifications(userId: userId)
        } catch {
            errorMessage = "Failed to load notifications. Please try again."
            print("Error fetching notifications: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Start Real-time Listener
    
    func startListening() {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        
        notificationService.startListening(userId: userId) { [weak self] notifications in
            self?.notifications = notifications
        }
    }
    
    func stopListening() {
        notificationService.stopListening()
    }
    
    // MARK: - Mark as Read
    
    func markAsRead(_ notification: Notification) async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        
        do {
            try await notificationService.markAsRead(
                notificationId: notification.id,
                userId: userId
            )
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
        } catch {
            errorMessage = "Failed to mark notification as read."
            print("Error marking notification as read: \(error.localizedDescription)")
        }
    }
    
    func markAllAsRead() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        
        do {
            try await notificationService.markAllAsRead(userId: userId)
            
            // Update local state
            for index in notifications.indices {
                notifications[index].isRead = true
            }
        } catch {
            errorMessage = "Failed to mark all notifications as read."
            print("Error marking all notifications as read: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Delete Notification
    
    func deleteNotification(_ notification: Notification) async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        
        do {
            try await notificationService.deleteNotification(
                notificationId: notification.id,
                userId: userId
            )
            
            // Update local state
            notifications.removeAll { $0.id == notification.id }
        } catch {
            errorMessage = "Failed to delete notification."
            print("Error deleting notification: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Create Sample Notifications (for testing)
    
    func createSampleNotifications() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        
        do {
            try await notificationService.createSampleNotifications(userId: userId)
            await fetchNotifications()
        } catch {
            errorMessage = "Failed to create sample notifications."
            print("Error creating sample notifications: \(error.localizedDescription)")
        }
    }
}

