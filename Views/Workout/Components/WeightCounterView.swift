import SwiftUI

struct WeightCounterView: View {
    @Binding var value: Double
    @FocusState private var isFocused: Bool
    @State private var textValue: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Kgs")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            HStack(spacing: 8) {
                // Minus button
                Button(action: {
                    if value >= 1.0 {
                        value -= 1.0
                        value = round(value * 10) / 10
                        updateTextValue()
                        HapticFeedback.impact()
                    } else if value > 0 {
                        value = 0.0
                        updateTextValue()
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
                TextField("0.0", text: $textValue)
                    .keyboardType(.decimalPad)
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
                    .onChange(of: textValue) { oldValue, newValue in
                        if let doubleValue = Double(newValue), doubleValue >= 0 {
                            value = round(doubleValue * 10) / 10
                        } else if newValue.isEmpty {
                            value = 0.0
                        }
                    }
                    .onAppear {
                        updateTextValue()
                    }
                
                // Plus button
                Button(action: {
                    value += 1.0
                    value = round(value * 10) / 10
                    updateTextValue()
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
        .onChange(of: value) { oldValue, newValue in
            if !isFocused {
                updateTextValue()
            }
        }
    }
    
    private func updateTextValue() {
        if value == 0.0 {
            textValue = ""
        } else {
            textValue = String(format: "%.1f", value)
        }
    }
}

#Preview {
    WeightCounterView(value: .constant(60.0))
        .padding()
        .background(Color(hex: "#F5F5F7"))
}
