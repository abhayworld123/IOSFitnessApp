import SwiftUI

struct GenderSelectionCard: View {
    let gender: Gender
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.impact(style: .light)
            onTap()
        }) {
            VStack(spacing: 12) {
                // Gender Icon
                if let uiImage = UIImage(named: gender.iconName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                } else {
                    // Fallback icon
                    Circle()
                        .fill(isSelected ? Color(hex: "#FFE5CC") : Color(hex: "#F5F5F7"))
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: gender == .male ? "person.fill" : "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(isSelected ? Color(hex: "#E89A3C") : Color(hex: "#8E8E93"))
                        )
                }
                
                // Gender Label
                Text(gender.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#E89A3C") : Color(hex: "#8E8E93"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .background(
                isSelected ? Color(hex: "#FFF5E9") : Color.white
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color(hex: "#E89A3C") : Color(hex: "#E5E5EA"),
                        lineWidth: isSelected ? 3 : 2
                    )
            )
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HStack(spacing: 16) {
        GenderSelectionCard(gender: .male, isSelected: true, onTap: {})
        GenderSelectionCard(gender: .female, isSelected: false, onTap: {})
    }
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
