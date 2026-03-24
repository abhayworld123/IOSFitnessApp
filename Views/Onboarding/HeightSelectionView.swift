import SwiftUI

private struct HeightPickerAnchors {
    var ruler: Anchor<CGRect>?
    var silhouette: Anchor<CGRect>?
}

private struct HeightPickerAnchorsKey: PreferenceKey {
    static var defaultValue = HeightPickerAnchors()
    static func reduce(value: inout HeightPickerAnchors, nextValue: () -> HeightPickerAnchors) {
        let next = nextValue()
        value.ruler = value.ruler ?? next.ruler
        value.silhouette = value.silhouette ?? next.silhouette
    }
}

struct HeightSelectionView: View {
    @Binding var basicDetails: BasicDetailsData
    let onBack: () -> Void
    let onNext: () -> Void
    let currentPage: Int
    let totalPages: Int
    
    @State private var currentHeight: Double = 170.0 // Always stored in cm
    @State private var heightText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var isUserScrolling = false
    @State private var heightUnit: HeightUnit = .cm
    
    private let heightRange: ClosedRange<Double> = 100...220 // Always in cm
    
    // Display height in current unit
    private var displayHeight: String {
        heightUnit.formatHeight(currentHeight)
    }
    
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
                        
                        // Height Selection Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What is your height?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                                .padding(.horizontal, 20)
                            
                            // Container wrapping ruler + silhouette + controls (362 x 380 per Figma)
                            VStack(spacing: 0) {
                                let rowHeight: CGFloat = 360
                                // Lower top inset = silhouette moves up (head closer to marker line)
                                let silhouetteTopInset = max(0, HeightRulerView.indicatorY - 80)

                                // Ruler and Silhouette Row with orange indicator line
                                ZStack(alignment: .center) {
                                    // Content: Number, Ruler, and Silhouette - centered (circle removed from here)
                                    HStack(alignment: .top, spacing: 8) {
                                        // Equal spacers on both sides to center content
                                        Spacer()

                                        // Space where the marker/value will sit (Figma puts the value near the marker,
                                        // not as a separate left column)
                                        Spacer().frame(width: 56)
                                        
                                        // Height Ruler (with beige background) - shift only ruler to the right
                                        HeightRulerView(selectedHeight: $currentHeight)
                                            .offset(x: 80) // Shift only the ruler to the right
                                            .anchorPreference(key: HeightPickerAnchorsKey.self, value: .bounds) {
                                                HeightPickerAnchors(ruler: $0, silhouette: nil)
                                            }
                                            .onChange(of: currentHeight) { oldValue, newValue in
                                                // Always update TextField when ruler changes
                                                if !isTextFieldFocused {
                                                    heightText = heightUnit.formatHeight(newValue)
                                                }
                                                
                                                // Haptic feedback on whole number changes
                                                let oldInt = Int(round(oldValue))
                                                let newInt = Int(round(newValue))
                                                if oldInt != newInt {
                                                    HapticFeedback.impact(style: .light)
                                                }
                                            }
                                        
                                        // Spacing between ruler and silhouette
                                        Spacer()
                                            .frame(width: 16)
                                        
                                        // Human Silhouette - head aligned with marker (fixed height)
                                        VStack(spacing: 0) {
                                            Spacer().frame(height: silhouetteTopInset)
                                            HumanSilhouetteView().padding(-10)
                                            
                                            Spacer()
                                        }
                                        .frame(height: rowHeight, alignment: .top)
                                        .anchorPreference(key: HeightPickerAnchorsKey.self, value: .bounds) {
                                            HeightPickerAnchors(ruler: nil, silhouette: $0)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                }
                                .frame(height: rowHeight)
                                .overlayPreferenceValue(HeightPickerAnchorsKey.self) { anchors in
                                    GeometryReader { proxy in
                                        let rulerFrame = anchors.ruler.map { proxy[$0] } ?? .zero
                                        let silhouetteFrame = anchors.silhouette.map { proxy[$0] } ?? .zero

                                        // Marker is fixed on the ruler center line (selection line), like Figma.
                                        let markerY = rulerFrame.minY + HeightRulerView.indicatorY
                                        let circleDiameter: CGFloat = 28
                                        let circleGapToRuler: CGFloat = 12
                                        let markerRightShift: CGFloat = 50 // Shift marker to the right
                                        let circleCenterX = rulerFrame.minX - circleGapToRuler - (circleDiameter / 2) + markerRightShift

                                        // Line extends from the circle across the ruler toward the silhouette head.
                                        // Extend it further into the silhouette to reach the head.
                                        let lineStartX = circleCenterX + (circleDiameter / 2)
                                        let lineEndX = silhouetteFrame.minX + (silhouetteFrame.width * 0.5) // Extend further into silhouette to reach head

                                        // Selected value sits below the marker near the circle (Figma).
                                        let valueY = markerY + 30

                                        ZStack(alignment: .topLeading) {
                                            // Line
                                            Path { p in
                                                p.move(to: CGPoint(x: lineStartX, y: markerY))
                                                p.addLine(to: CGPoint(x: lineEndX, y: markerY))
                                            }
                                            .stroke(Color(hex: "#D89644"), lineWidth: 2)

                                            // Circle
                                            Circle()
                                                .fill(Color(hex: "#D89644"))
                                                .frame(width: circleDiameter, height: circleDiameter)
                                                .overlay(
                                                    Circle().stroke(Color.white, lineWidth: 3)
                                                )
                                                .position(x: circleCenterX, y: markerY)

                                            // Value label (format per unit)
                                            Text(displayHeight)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(hex: "#2C2C2E"))
                                                // Slightly to the right of the circle, below the line (Figma)
                                                .position(x: circleCenterX + (circleDiameter / 2) + 22, y: valueY)
                                        }
                                        .allowsHitTesting(false)
                                    }
                                }
                                
                                // Bottom controls
                                HStack(spacing: 16) {
                                    // Unit selector (CM) - functional dropdown
                                    HeightUnitSelectorView(selectedUnit: $heightUnit)
                                    
                                    Spacer()
                                    
                                    // Value display - editable TextField
                                    ZStack {
                                        // Text View (Visible when NOT editing)
                                        if !isTextFieldFocused {
                                            Text(displayHeight)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(Color(hex: "#2C2C2E"))
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    heightText = displayHeight
                                                    isTextFieldFocused = true
                                                }
                                        }
                                        
                                        // TextField (Visible when editing)
                                        TextField("", text: $heightText)
                                            .keyboardType(heightUnit == .cm ? .numberPad : .default)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color(hex: "#2C2C2E"))
                                            .multilineTextAlignment(.center)
                                            .focused($isTextFieldFocused)
                                            .opacity(isTextFieldFocused ? 1 : 0)
                                            .frame(minWidth: 50) // Minimum width for editing
                                            .onChange(of: heightText) { _, newValue in
                                                guard isTextFieldFocused else { return }
                                                
                                                // Filter input based on unit
                                                let filtered: String
                                                if heightUnit == .cm {
                                                    // Only allow digits for CM
                                                    filtered = newValue.filter { $0.isNumber }
                                                } else {
                                                    // Allow digits, apostrophe, quote, and space for FT/IN
                                                    filtered = newValue.filter { $0.isNumber || $0 == "'" || $0 == "\"" || $0 == " " }
                                                }
                                                
                                                if filtered != newValue {
                                                    heightText = filtered
                                                    return
                                                }
                                                
                                                // Parse height based on current unit
                                                if let heightInCm = heightUnit.parseHeight(filtered) {
                                                    let clamped = max(heightRange.lowerBound, min(heightRange.upperBound, heightInCm))
                                                    if clamped != currentHeight {
                                                        isUserScrolling = true
                                                        currentHeight = clamped
                                                        // Reset flag after animation
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                            isUserScrolling = false
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                    .fixedSize() // Prevent expansion, size to content
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(hex: "#E5E5EA"), lineWidth: 1)
                                    )
                                }
                                .padding(.top, -20) // Remove extra space above controls
                            }
                            .frame(width: 362) // Match Figma width, height will be flexible
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
                        basicDetails.height = currentHeight
                        basicDetails.heightUnit = heightUnit
                        HapticFeedback.impact()
                        onNext()
                    }) {
                        Text("Save & Next")
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
                heightText = heightUnit.formatHeight(currentHeight)
            } else {
                // When keyboard dismisses, sync text with current height
                heightText = heightUnit.formatHeight(currentHeight)
            }
        }
        .onChange(of: heightUnit) { _, newUnit in
            // Update display when unit changes
            heightText = newUnit.formatHeight(currentHeight)
        }
        .onAppear {
            heightUnit = basicDetails.heightUnit
            // Initialize height
            if let height = basicDetails.height {
                currentHeight = height
            } else {
                currentHeight = 170.0 // Default
            }
            heightText = heightUnit.formatHeight(currentHeight)
        }
    }
}

#Preview {
    HeightSelectionView(
        basicDetails: .constant(BasicDetailsData()),
        onBack: {},
        onNext: {},
        currentPage: 4,
        totalPages: 5
    )
}
