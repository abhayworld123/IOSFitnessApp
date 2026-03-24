import SwiftUI

struct WeightRulerView: View {
    @Binding var selectedWeight: Double
    let unit: WeightUnit
    @State private var lastHapticValue: Int = 0
    @State private var scrollTimer: Timer?
    @State private var isUserScrolling = false
    
    private let spacing: CGFloat = 50 // 50px per unit
    private let scrollSensitivity: CGFloat = 0.5 // Lower = slower scroll (0.5 = half speed)
    
    private var range: ClosedRange<Double> {
        unit.range
    }
    
    var body: some View {
        ZStack {
            // Scrollable ruler
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        // Leading spacer
                        Color.clear
                            .frame(width: UIScreen.main.bounds.width / 2)
                        
                        // Tick marks
                        ForEach(Int(range.lowerBound)...Int(range.upperBound), id: \.self) { value in
                            let tickKind: RulerTickKind = {
                                if value % 10 == 0 { return .major }
                                if value % 5 == 0 { return .mid }
                                return .minor
                            }()
                            let aligned = abs(selectedWeight - Double(value)) < 0.5
                            TickMarkView(
                                value: Double(value),
                                tickKind: tickKind,
                                isAlignedWithSelection: aligned
                            )
                            .frame(width: spacing)
                            .id(Double(value))
                        }
                        
                        // Trailing spacer
                        Color.clear
                            .frame(width: UIScreen.main.bounds.width / 2)
                    }
                }
                .onAppear {
                    // Initial scroll
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo(selectedWeight, anchor: .center)
                    }
                }
                .onChange(of: selectedWeight) { oldValue, newValue in
                    // Scroll when value changes from input
                    if !isUserScrolling && abs(oldValue - newValue) > 0.5 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            proxy.scrollTo(round(newValue), anchor: .center)
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isUserScrolling {
                                isUserScrolling = true
                            }
                            
                            // Cancel previous snap timer
                            scrollTimer?.invalidate()
                        }
                        .onEnded { value in
                            // Calculate which tick mark is closest to center
                            // Apply sensitivity multiplier to slow down scroll
                            let translation = value.translation.width * scrollSensitivity
                            let ticksScrolled = -translation / spacing
                            let newWeight = selectedWeight + ticksScrolled
                            let clampedWeight = max(Double(range.lowerBound), min(Double(range.upperBound), newWeight))
                            let snappedWeight = round(clampedWeight)
                            
                            print("📊 Drag ended. Snapping to: \(snappedWeight)")
                            
                            // Update weight
                            selectedWeight = snappedWeight
                            
                            // Snap with animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                proxy.scrollTo(snappedWeight, anchor: .center)
                            }
                            
                            HapticFeedback.impact(style: .medium)
                            
                            // Reset scrolling flag after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isUserScrolling = false
                            }
                        }
                )
            }
            .frame(height: RulerLayout.whitePanelHeight)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            
            // Red caret — sits in upper margin above tick lines
            VStack(spacing: 0) {
                Triangle()
                    .fill(Color(hex: "#FF3B30"))
                    .frame(width: 18, height: 11)
                    .padding(.top, RulerLayout.caretTopPadding)
                Spacer()
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Ruler layout constants

private enum RulerLayout {
    /// White rounded panel total height (room under caret + ticks + labels).
    static let whitePanelHeight: CGFloat = 154
    /// Space from top of panel to start of tick band (~35% clear area under triangle).
    static let tickColumnTopInset: CGFloat = 52
    /// Shared band height so all tick bottoms align before the label row.
    static let tickBandHeight: CGFloat = 62
    static let caretTopPadding: CGFloat = 8
}

// MARK: - Tick scale

enum RulerTickKind {
    case major  // every 10
    case mid    // every 5
    case minor  // other integers
}

// MARK: - Preference Key
struct WeightScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Tick Mark View
struct TickMarkView: View {
    let value: Double
    let tickKind: RulerTickKind
    /// True when this integer is the one under the center pointer.
    let isAlignedWithSelection: Bool
    
    private var tickWidth: CGFloat {
        if tickKind == .major, isAlignedWithSelection { return 3 }
        if tickKind == .major { return 2 }
        if tickKind == .mid { return 1.5 }
        return 1
    }
    
    private var tickHeight: CGFloat {
        switch tickKind {
        case .major:
            return isAlignedWithSelection ? 56 : 50
        case .mid:
            return 26
        case .minor:
            return 13
        }
    }
    
    private var tickColor: Color {
        if tickKind == .major, isAlignedWithSelection {
            return Color(hex: "#1C1C1E")
        }
        switch tickKind {
        case .major:
            return Color(hex: "#8E8E93")
        case .mid:
            return Color(hex: "#AEAEB2")
        case .minor:
            return Color(hex: "#D1D1D6")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: RulerLayout.tickColumnTopInset)

            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(tickColor)
                    .frame(width: tickWidth, height: tickHeight)
            }
            .frame(height: RulerLayout.tickBandHeight)

            Spacer()
                .frame(height: 10)

            if tickKind == .major {
                Text(String(format: "%.0f", value))
                    .font(.system(size: isAlignedWithSelection ? 18 : 15, weight: isAlignedWithSelection ? .bold : .regular))
                    .foregroundColor(isAlignedWithSelection ? Color(hex: "#1C1C1E") : Color(hex: "#8E8E93"))
            } else {
                Color.clear
                    .frame(height: 20)
            }

            Spacer(minLength: 0)
        }
        .frame(height: RulerLayout.whitePanelHeight)
        .animation(.easeInOut(duration: 0.2), value: isAlignedWithSelection)
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
