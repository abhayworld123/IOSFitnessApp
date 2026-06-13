import Foundation

enum NotificationDeepLink {
    static let navigateNotification = Foundation.Notification.Name("TrakkitDeepLinkNavigate")

    struct Payload {
        let destination: Destination
        let workoutId: String?
    }

    enum Destination: String {
        case dashboard
        case water
        case steps
        case weight
        case sleep
        case calendar
        case notifications
        case workoutStart
    }

    static func post(actionURL: String?) {
        guard let payload = parse(actionURL) else { return }
        NotificationCenter.default.post(
            name: navigateNotification,
            object: nil,
            userInfo: [
                "destination": payload.destination.rawValue,
                "workoutId": payload.workoutId as Any
            ]
        )
    }

    static func parse(_ actionURL: String?) -> Payload? {
        guard let raw = actionURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw) else { return nil }

        let host = (url.host ?? url.pathComponents.dropFirst().first)?.lowercased() ?? ""
        let pathParts = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "dashboard":
            return Payload(destination: .dashboard, workoutId: nil)
        case "water":
            return Payload(destination: .water, workoutId: nil)
        case "steps":
            return Payload(destination: .steps, workoutId: nil)
        case "weight":
            return Payload(destination: .weight, workoutId: nil)
        case "sleep":
            return Payload(destination: .sleep, workoutId: nil)
        case "calendar":
            return Payload(destination: .calendar, workoutId: nil)
        case "notifications":
            return Payload(destination: .notifications, workoutId: nil)
        case "workout":
            if pathParts.count >= 2, pathParts[1] == "start" {
                return Payload(destination: .workoutStart, workoutId: pathParts[0])
            }
            if let id = pathParts.first {
                return Payload(destination: .workoutStart, workoutId: id)
            }
            return nil
        default:
            return nil
        }
    }
}
