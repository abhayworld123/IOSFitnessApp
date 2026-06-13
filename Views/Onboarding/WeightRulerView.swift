import SwiftUI

/// Horizontal weight ruler: 0.1 kg or 0.5 lb steps, drag to change value.
struct WeightRulerView: View {
    @Binding var selectedWeight: Double
    let unit: WeightUnit
    /// `true` = weight-tracker card layout (left marker, compact ticks).
    var embeddedInCard: Bool = false

    @State private var dragStartWeight: Double = 0
    @State private var isDragging: Bool = false
    @State private var lastHapticWeight: Double = -1

    private var pointsPerUnit: CGFloat { embeddedInCard ? 58 : 50 }

    private var range: ClosedRange<Double> { unit.range }

    private var step: Double {
        switch unit {
        case .kg: return 0.1
        case .lbs: return 0.5
        }
    }

    private var pointsPerStep: CGFloat { CGFloat(step) * pointsPerUnit }

    var body: some View {
        GeometryReader { geo in
            let markerX = embeddedInCard ? RulerLayout.embeddedMarkerX : geo.size.width / 2
            let totalWidth = CGFloat(stepCount) * pointsPerStep
            let scrollX = markerX - positionX(for: selectedWeight)
            let tickTop = RulerLayout.tickColumnTop(embedded: embeddedInCard)
            let markerY = tickTop + RulerLayout.tickBandHeight(embedded: embeddedInCard) / 2

            VStack(spacing: RulerLayout.gapTickToLabel(embedded: embeddedInCard)) {
                ZStack(alignment: .topLeading) {
                    if !embeddedInCard {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    }

                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(0..<stepCount, id: \.self) { i in
                            WeightRulerTickView(
                                value: valueAt(index: i),
                                step: step,
                                embedded: embeddedInCard,
                                columnWidth: pointsPerStep
                            )
                        }
                    }
                    .frame(width: totalWidth, height: tickTop + RulerLayout.tickBandHeight(embedded: embeddedInCard), alignment: .bottomLeading)
                    .offset(x: scrollX, y: 0)

                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(RulerLayout.markerColor(embedded: embeddedInCard))
                        .frame(
                            width: embeddedInCard ? 2 : 3,
                            height: RulerLayout.markerHeight(embedded: embeddedInCard)
                        )
                        .position(x: markerX, y: markerY)
                }
                .frame(height: RulerLayout.tickAreaHeight(embedded: embeddedInCard))
                .clipped()

                rulerLabelRow(scrollX: scrollX, totalWidth: totalWidth)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture())
        }
        .frame(height: RulerLayout.totalHeight(embedded: embeddedInCard))
        .onAppear {
            selectedWeight = snap(clamp(selectedWeight))
            lastHapticWeight = selectedWeight
        }
    }

    @ViewBuilder
    private func rulerLabelRow(scrollX: CGFloat, totalWidth: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(0..<stepCount, id: \.self) { i in
                let value = valueAt(index: i)
                ZStack(alignment: .center) {
                    Color.clear
                    if isWholeNumber(value) {
                        Text(String(format: "%.0f", value))
                            .font(.system(size: embeddedInCard ? 14 : 13, weight: embeddedInCard ? .medium : .semibold, design: .rounded))
                            .foregroundColor(embeddedInCard ? Color(hex: "#8E8E93") : Color(hex: "#3C3C43"))
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(width: pointsPerUnit, alignment: .center)
                            .offset(x: (pointsPerStep - pointsPerUnit) / 2)
                    }
                }
                .frame(width: pointsPerStep, height: RulerLayout.labelRowHeight, alignment: .top)
            }
        }
        .frame(width: totalWidth, height: RulerLayout.labelRowHeight, alignment: .topLeading)
        .offset(x: scrollX, y: 0)
    }

    private var stepCount: Int { max(0, Int(round((range.upperBound - range.lowerBound) / step)) + 1) }

    private func valueAt(index: Int) -> Double {
        round((range.lowerBound + Double(index) * step) * 1000) / 1000
    }

    private func isWholeNumber(_ value: Double) -> Bool {
        abs(value - value.rounded()) < 0.0001
    }

    private func positionX(for weight: Double) -> CGFloat {
        CGFloat((weight - range.lowerBound) * pointsPerUnit)
    }

    private func clamp(_ w: Double) -> Double {
        min(max(w, range.lowerBound), range.upperBound)
    }

    private func snap(_ w: Double) -> Double {
        (w / step).rounded() * step
    }

    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if !isDragging {
                    dragStartWeight = selectedWeight
                    isDragging = true
                }
                var w = dragStartWeight - g.translation.width / pointsPerUnit
                w = snap(clamp(w))
                if abs(w - lastHapticWeight) >= step * 0.9 {
                    HapticFeedback.impact(style: .light)
                    lastHapticWeight = w
                }
                selectedWeight = w
            }
            .onEnded { _ in
                isDragging = false
                selectedWeight = snap(clamp(selectedWeight))
                lastHapticWeight = selectedWeight
                HapticFeedback.impact(style: .light)
            }
    }
}

// MARK: - One tick

private struct WeightRulerTickView: View {
    let value: Double
    let step: Double
    var embedded: Bool
    var columnWidth: CGFloat

    private var kind: RulerWeightTickKind {
        if isOnWholeNumber(value) { return .major }
        if embedded { return .minor }
        if isOnHalfNumber(value) { return .mid }
        return .minor
    }

    private func isOnWholeNumber(_ v: Double) -> Bool {
        abs(v - v.rounded()) < 0.0001
    }

    private func isOnHalfNumber(_ v: Double) -> Bool {
        if isOnWholeNumber(v) { return false }
        if step > 0.2 { return false }
        return abs(2 * v - (2 * v).rounded()) < 0.0001
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer(minLength: 0)
            Rectangle()
                .fill(tickColor)
                .frame(width: tickWidth, height: tickHeight)
        }
        .frame(
            width: columnWidth,
            height: RulerLayout.tickColumnTop(embedded: embedded) + RulerLayout.tickBandHeight(embedded: embedded),
            alignment: .bottom
        )
    }

    private var tickWidth: CGFloat {
        if kind == .major { return embedded ? 2 : 2.5 }
        return 1
    }

    private var tickHeight: CGFloat {
        if embedded {
            return kind == .major ? 36 : 10
        }
        switch kind {
        case .major: return 52
        case .mid: return 28
        case .minor: return 12
        }
    }

    private var tickColor: Color {
        if kind == .major { return Color(hex: "#1C1C1E") }
        return Color(hex: embedded ? "#C7C7CC" : "#AEAEB2")
    }
}

private enum RulerWeightTickKind {
    case major, mid, minor
}

// MARK: - Layout

private enum RulerLayout {
    /// Left-edge selection line on the weight-tracker card (matches Figma).
    static let embeddedMarkerX: CGFloat = 22

    static func tickBandHeight(embedded: Bool) -> CGFloat { embedded ? 44 : 58 }
    static func markerHeight(embedded: Bool) -> CGFloat { embedded ? 44 : 60 }
    static func gapTickToLabel(embedded: Bool) -> CGFloat { embedded ? 10 : 8 }
    static let labelRowHeight: CGFloat = 20

    static func tickColumnTop(embedded: Bool) -> CGFloat { embedded ? 0 : 10 }

    static func tickAreaHeight(embedded: Bool) -> CGFloat {
        tickColumnTop(embedded: embedded) + tickBandHeight(embedded: embedded)
    }

    static func totalHeight(embedded: Bool) -> CGFloat {
        tickAreaHeight(embedded: embedded) + gapTickToLabel(embedded: embedded) + labelRowHeight + (embedded ? 4 : 6)
    }

    static func markerColor(embedded: Bool) -> Color {
        embedded ? Color(hex: "#EE8924") : Color(hex: "#E53935")
    }
}

// MARK: - Weight tracker empty card ruler (Figma — left orange marker, 75/76/77 window)

/// Lightweight ruler for the empty weight card. Renders only the visible tick window
/// so labels stay aligned and never overlap.
struct WeightTrackerCardRulerView: View {
    @Binding var value: Double
    let unit: WeightUnit
    var onSlideEnded: ((Double) -> Void)?

    @State private var dragStartWeight: Double = 0
    @State private var isDragging = false

    private let markerX: CGFloat = 22
    private let pointsPerUnit: CGFloat = 56
    private let accent = Color(hex: "#EE8924")

    private var step: Double { unit == .kg ? 0.1 : 0.5 }
    private var range: ClosedRange<Double> { unit.range }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let ticks = visibleTickValues(width: width)
            let majors = ticks.filter(isWholeNumber)

            ZStack(alignment: .topLeading) {
                ForEach(ticks, id: \.self) { tickValue in
                    let x = xPosition(for: tickValue, width: width)
                    tickMark(for: tickValue)
                        .position(x: x, y: 22)
                }

                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(accent)
                    .frame(width: 2, height: 44)
                    .position(x: markerX, y: 22)
                    .zIndex(10)

                ForEach(majors, id: \.self) { major in
                    Text(String(format: "%.0f", major))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#8E8E93"))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                        .position(x: xPosition(for: major, width: width), y: 58)
                }
            }
            .frame(width: width, height: 74, alignment: .topLeading)
            .clipped()
            .contentShape(Rectangle())
            .gesture(dragGesture())
        }
        .frame(height: 74)
        .onAppear {
            value = snap(clamp(value))
        }
    }

    @ViewBuilder
    private func tickMark(for tickValue: Double) -> some View {
        let major = isWholeNumber(tickValue)
        Rectangle()
            .fill(major ? Color(hex: "#1C1C1E") : Color(hex: "#C7C7CC"))
            .frame(width: major ? 2 : 1, height: major ? 36 : 10)
    }

    private func xPosition(for tickValue: Double, width: CGFloat) -> CGFloat {
        markerX + CGFloat(tickValue - value) * pointsPerUnit
    }

    private func visibleTickValues(width: CGFloat) -> [Double] {
        let spanRight = Double((width - markerX + 24) / pointsPerUnit)
        let minV = max(range.lowerBound, value - 1.2)
        let maxV = min(range.upperBound, value + spanRight)
        var out: [Double] = []
        var v = (minV / step).rounded(.down) * step
        while v <= maxV + step * 0.5 {
            out.append((v * 10).rounded() / 10)
            v += step
        }
        return out
    }

    private func isWholeNumber(_ v: Double) -> Bool {
        abs(v - v.rounded()) < 0.001
    }

    private func clamp(_ w: Double) -> Double {
        min(max(w, range.lowerBound), range.upperBound)
    }

    private func snap(_ w: Double) -> Double {
        (w / step).rounded() * step
    }

    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                if !isDragging {
                    dragStartWeight = value
                    isDragging = true
                }
                var w = dragStartWeight - Double(g.translation.width / pointsPerUnit)
                w = snap(clamp(w))
                value = w
            }
            .onEnded { _ in
                isDragging = false
                value = snap(clamp(value))
                onSlideEnded?(value)
                HapticFeedback.impact(style: .light)
            }
    }
}
