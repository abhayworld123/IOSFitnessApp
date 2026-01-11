import Foundation

enum NotificationType: String, Codable, CaseIterable {
    case workout = "workout"
    case achievement = "achievement"
    case plan = "plan"
    case reminder = "reminder"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .workout:
            return "Workout"
        case .achievement:
            return "Achievement"
        case .plan:
            return "Plan"
        case .reminder:
            return "Reminder"
        case .system:
            return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .workout:
            return "figure.run"
        case .achievement:
            return "trophy.fill"
        case .plan:
            return "calendar"
        case .reminder:
            return "bell.fill"
        case .system:
            return "info.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .workout:
            return "#FF6B35" // Primary orange
        case .achievement:
            return "#FFD700" // Gold
        case .plan:
            return "#004E89" // Secondary blue
        case .reminder:
            return "#FF6B35" // Primary orange
        case .system:
            return "#808080" // Gray
        }
    }
}

struct Notification: Identifiable, Codable {
    let id: String
    var type: NotificationType
    var title: String
    var message: String
    var timestamp: Date
    var isRead: Bool
    var actionURL: String? // Optional deep link or navigation path
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        actionURL: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionURL = actionURL
    }
}

// MARK: - Date Grouping Helper
extension Notification {
    var dateGroup: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(timestamp) {
            return "Today"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: now)?.contains(timestamp) == true {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: timestamp)
        }
    }
}

