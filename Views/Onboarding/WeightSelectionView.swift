import SwiftUI

struct WeightSelectionView: View {
    @Binding var basicDetails: BasicDetailsData
    let onBack: () -> Void
    let onNext: () -> Void
    let currentPage: Int
    let totalPages: Int
    
    @State private var displayWeight: Double = 70.0
    @State private var weightText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // White Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: {
                        HapticFeedback.impact(style: .light)
                        onBack()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basic details")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                            
                            Text("In order to calculate your data properly we need your basic information")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#A8A8A8"))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        
                        // Weight Selection Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What is your current weight?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                                .padding(.horizontal, 20)
                            
                            // Gray container wrapping ruler + controls
                            VStack(spacing: 20) {
                                // Weight Ruler
                                WeightRulerView(
                                    selectedWeight: $displayWeight,
                                    unit: basicDetails.weightUnit
                                )
                                
                                // Bottom controls
                                HStack(spacing: 16) {
                                    // Unit selector
                                    UnitSelectorView(selectedUnit: $basicDetails.weightUnit)
                                    
                                    Spacer()
                                    
                                    // Value display - editable TextField
                                    ZStack {
                                        // 1. Text View (Visible when NOT editing)
                                        // Shows the live weight from the ruler
                                        if !isTextFieldFocused {
                                            Text(String(format: "%.0f", displayWeight))
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(Color(hex: "#2C2C2E"))
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .contentShape(Rectangle()) // Make entire area tappable
                                                .onTapGesture {
                                                    // Prepare text and switch to edit mode
                                                    weightText = String(format: "%.0f", displayWeight)
                                                    isTextFieldFocused = true
                                                }
                                        }
                                        
                                        // 2. TextField (Visible when editing)
                                        // Hidden (opacity 0) when not focused to keep layout stable, 
                                        // but zIndex ensures Text is on top when visible
                                        TextField("", text: $weightText)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(Color(hex: "#2C2C2E"))
                                            .multilineTextAlignment(.center)
                                            .focused($isTextFieldFocused)
                                            .opacity(isTextFieldFocused ? 1 : 0)
                                            .onChange(of: weightText) { _, newValue in
                                                // Only process if user is typing
                                                guard isTextFieldFocused else { return }
                                                
                                                // Filter to only digits
                                                let filtered = newValue.filter { $0.isNumber }
                                                if filtered != newValue {
                                                    weightText = filtered
                                                }
                                                
                                                // Update weight if valid
                                                if let weight = Double(filtered) {
                                                    let range = basicDetails.weightUnit.range
                                                    if range.contains(weight) {
                                                        displayWeight = weight
                                                    }
                                                }
                                            }
                                    }
                                    .frame(minWidth: 100, minHeight: 60)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 24)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "#E5E5EA"), lineWidth: 2)
                                    )
                                }
                            }
                            .padding(20)
                            .background(Color(hex: "#F5F5F7"))
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 16) {
                    // Next Button
                    Button(action: {
                        // Save weight in KG (internal storage)
                        if basicDetails.weightUnit == .lbs {
                            basicDetails.weight = basicDetails.weightUnit.convert(displayWeight, to: .kg)
                        } else {
                            basicDetails.weight = displayWeight
                        }
                        
                        HapticFeedback.impact()
                        onNext()
                    }) {
                        Text("Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#D89644"))
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 30)
                    
                    // Page Indicator
                    PageIndicatorView(currentPage: currentPage, totalPages: totalPages)
                        .padding(.bottom, 30)
                }
            }
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if focused {
                // Prepare for editing
                weightText = String(format: "%.0f", displayWeight)
            } else {
                // When keyboard dismisses, clear text (will rely on displayWeight)
                weightText = ""
            }
        }
        .onChange(of: basicDetails.weightUnit) { _, newUnit in
            // Convert weight when unit changes
            let oldUnit: WeightUnit = newUnit == .kg ? .lbs : .kg
            displayWeight = oldUnit.convert(displayWeight, to: newUnit)
            weightText = "\(Int(round(displayWeight)))"
        }
        .onAppear {
            // Initialize display weight
            if let weight = basicDetails.weight {
                displayWeight = basicDetails.weightUnit == .kg ? weight : WeightUnit.kg.convert(weight, to: .lbs)
            } else {
                displayWeight = basicDetails.weightUnit.defaultValue
            }
            weightText = "\(Int(round(displayWeight)))"
        }
    }
}

#Preview {
    WeightSelectionView(
        basicDetails: .constant(BasicDetailsData()),
        onBack: {},
        onNext: {},
        currentPage: 3,
        totalPages: 4
    )
}
