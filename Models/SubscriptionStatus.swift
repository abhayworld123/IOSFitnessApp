import Foundation

enum SubscriptionStatus: String, Codable {
    case free
    case premium
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .premium:
            return "Premium"
        }
    }
}

