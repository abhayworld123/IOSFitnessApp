import SwiftUI

struct RepsCounterView: View {
    @Binding var value: Int
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Reps")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            HStack(spacing: 8) {
                // Minus button
                Button(action: {
                    if value > 0 {
                        value -= 1
                        HapticFeedback.impact()
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#E5E5EA"))
                        .clipShape(Circle())
                }
                
                // Input field
                TextField("0", value: $value, format: .number)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .multilineTextAlignment(.center)
                    .frame(width: 50, height: 44)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#FF9500"), lineWidth: 2)
                    )
                    .focused($isFocused)
                    .onChange(of: value) { oldValue, newValue in
                        if newValue < 0 {
                            value = 0
                        }
                    }
                
                // Plus button
                Button(action: {
                    value += 1
                    HapticFeedback.impact()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#E5E5EA"))
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview {
    RepsCounterView(value: .constant(12))
        .padding()
        .background(Color(hex: "#F5F5F7"))
}
