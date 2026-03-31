import SwiftUI
import UIKit

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0,
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 0
                    }
                }
            )
            
            TabBarButton(
                icon: "calendar",
                title: "Calendar",
                isSelected: selectedTab == 1,
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 1
                    }
                }
            )
            
            TabBarButton(
                icon: "play.fill",
                title: "Video",
                isSelected: selectedTab == 2,
                action: { 
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = 2
                    }
                }
            )
            
            TabBarButton(
                icon: "person.fill",
                title: "Profile",
                isSelected: selectedTab == 3,
                customImageName: "ProfileTabIcon",
                customImageNameSelected: "ProfileTabIconSelected",
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
    let icon: String
    let title: String
    let isSelected: Bool
    var customImageName: String? = nil
    var customImageNameSelected: String? = nil
    let action: () -> Void
    
    private var effectiveCustomImageName: String? {
        if isSelected, let selected = customImageNameSelected { return selected }
        return customImageName
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#2A2A2A"))
                            .frame(width: 40, height: 40)
                    }
                    
                    if let name = effectiveCustomImageName {
                        Image(name)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: isSelected ? 18 : 20, height: isSelected ? 18 : 20)
                            .foregroundColor(isSelected ? .white : Color(hex: "#7E7E7E"))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: isSelected ? 20 : 22, weight: isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : Color(hex: "#7E7E7E"))
                    }
                }
                .frame(height: 40)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Color(hex: "#2A2A2A") : Color(hex: "#7E7E7E"))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
