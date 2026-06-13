import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                assetName: "home",
                title: "Home",
                isSelected: selectedTab == 0,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
            )

            TabBarButton(
                assetName: "dumble",
                title: "Workout",
                isSelected: selectedTab == 1,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
            )

            TabBarButton(
                assetName: "play",
                title: "Video",
                isSelected: selectedTab == 2,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            )

            TabBarButton(
                assetName: "profilecircle",
                title: "Profile",
                isSelected: selectedTab == 3,
                action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 3
                    }
                }
            )
        }
        .frame(height: 70)
        .padding(.bottom, 30)
        .background(Color(hex: "#F5F5F7"))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        .padding(.horizontal, 0)
        .offset(y: 35)
    }
}

struct TabBarButton: View {
    let assetName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    private let inactiveIconGray = Color(hex: "#7E7E7E")
    private let pillBlack = Color(hex: "#1A1A1A")

    var body: some View {
        Button(action: action) {
            Group {
                if isSelected {
                    HStack {
                        Spacer(minLength: 0)
                        HStack(spacing: 8) {
                            tabAssetImage(selected: true)
                            Text(title.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(pillBlack)
                        .clipShape(Capsule())
                        Spacer(minLength: 0)
                    }
                } else {
                    tabAssetImage(selected: false)
                        .frame(maxWidth: .infinity, maxHeight: 44, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func tabAssetImage(selected: Bool) -> some View {
        Image(assetName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: selected ? 20 : 24, height: selected ? 20 : 24)
            .foregroundColor(selected ? .white : inactiveIconGray)
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
