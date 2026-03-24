import SwiftUI

struct HeightUnitSelectorView: View {
    @Binding var selectedUnit: HeightUnit
    @State private var showPicker = false
    
    var body: some View {
        Button(action: {
            showPicker = true
            HapticFeedback.impact(style: .light)
        }) {
            HStack(spacing: 8) {
                Text(selectedUnit.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C2C2E"))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E5E5EA"), lineWidth: 1)
            )
        }
        .actionSheet(isPresented: $showPicker) {
            ActionSheet(
                title: Text("Select Unit"),
                buttons: HeightUnit.allCases.map { unit in
                    .default(Text(unit.displayName)) {
                        withAnimation {
                            selectedUnit = unit
                        }
                        HapticFeedback.impact(style: .light)
                    }
                } + [.cancel()]
            )
        }
    }
}

#Preview {
    HeightUnitSelectorView(selectedUnit: .constant(.cm))
        .padding()
}
