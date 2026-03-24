import Foundation

struct Badge: Identifiable {
    let id: String
    let title: String
    /// Asset name in Assets.xcassets (e.g. "badge", "fire", "kg")
    let imageName: String
}
