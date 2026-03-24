import SwiftUI

struct HeightRulerView: View {
    @Binding var selectedHeight: Double
    @State private var lastHapticValue: Int = 0
    @State private var isUserScrolling = false
    @State private var scrollOffset: CGFloat = 0
    
    // Selection line position inside the ruler viewport (from top).
    // Figma places the selection line higher than center.
    static let indicatorY: CGFloat = 86

    // Figma-like density: smaller spacing so multiple ticks are visible at once
    private let spacing: CGFloat = 10 // points per cm
    private let heightRange: ClosedRange<Double> = 100...220 // cm
    private let indicatorY: CGFloat = HeightRulerView.indicatorY
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background ruler (wider to match Figma)
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#FDF4EB"))
                    .frame(width: 88) // Increased width to match Figma
                
                // Scrollable ruler with tick marks
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Top spacer
                            Color.clear
                                .frame(height: indicatorY)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: -geo.frame(in: .named("scroll")).minY
                                        )
                                    }
                                )
                            
                            // Tick marks
                            ForEach(Int(heightRange.lowerBound)...Int(heightRange.upperBound), id: \.self) { value in
                                HeightTickMarkView(
                                    value: Double(value),
                                    isSelected: abs(selectedHeight - Double(value)) < 0.5,
                                    isMajor: value % 10 == 0
                                )
                                .frame(height: spacing)
                                .id(Double(value))
                            }
                            
                            // Bottom spacer
                            Color.clear
                                .frame(height: (280 - indicatorY))
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        // Calculate height from scroll position
                        let totalOffset = offset - indicatorY
                        let cmFromTop = totalOffset / spacing
                        let calculatedHeight = heightRange.upperBound - cmFromTop
                        let clampedHeight = max(heightRange.lowerBound, min(heightRange.upperBound, calculatedHeight))
                        let roundedHeight = round(clampedHeight)
                        
                        // Always update height as user scrolls (real-time updates)
                        if abs(selectedHeight - roundedHeight) >= 0.5 {
                            selectedHeight = roundedHeight
                            
                            // Haptic feedback on whole number changes
                            let newInt = Int(roundedHeight)
                            if lastHapticValue != newInt {
                                lastHapticValue = newInt
                                HapticFeedback.impact(style: .light)
                            }
                        }
                    }
                    .onAppear {
                        // Initial scroll to selected height
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(round(selectedHeight), anchor: .center)
                        }
                    }
                    .onChange(of: selectedHeight) { oldValue, newValue in
                        // Scroll when value changes from input (TextField)
                        if !isUserScrolling && abs(oldValue - newValue) > 0.5 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                proxy.scrollTo(round(newValue), anchor: .center)
                            }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isUserScrolling {
                                    isUserScrolling = true
                                }
                            }
                            .onEnded { _ in
                                // Snap to nearest whole number
                                let snappedHeight = round(selectedHeight)
                                selectedHeight = snappedHeight
                                
                                // Snap with animation
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    proxy.scrollTo(snappedHeight, anchor: .center)
                                }
                                
                                HapticFeedback.impact(style: .medium)
                                
                                // Reset scrolling flag
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isUserScrolling = false
                                }
                            }
                    )
                }
                
                // Note: Orange circle and number will be drawn in parent view
            }
        }
        .frame(width: 88, height: 280) // Match Figma height (reduced from 400)
    }
}

// MARK: - Height Tick Mark View
struct HeightTickMarkView: View {
    let value: Double
    let isSelected: Bool
    let isMajor: Bool
    
    var body: some View {
        // Figma-style tick marks: no side labels, varying tick lengths
        let intValue = Int(value.rounded())
        let isMid = intValue % 5 == 0 && intValue % 10 != 0
        let tickWidth: CGFloat = isMajor ? 44 : (isMid ? 32 : 20)
        let tickHeight: CGFloat = isMajor ? 2 : 1
        let tickColor = isMajor ? Color(hex: "#8E8E93") : Color(hex: "#C7C7CC")

        HStack(spacing: 0) {
            Spacer()
            Rectangle()
                .fill(tickColor)
                .frame(width: tickWidth, height: tickHeight)
            Spacer()
        }
    }
}

#Preview {
    HeightRulerView(selectedHeight: .constant(175))
        .padding()
}
