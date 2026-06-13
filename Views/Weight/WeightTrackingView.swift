import SwiftUI
import Charts

struct WeightTrackingView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WeightTrackingViewModel
    @State private var showGoalSheet = false
    @State private var progressTab: ProgressMetric = .weight
    @State private var isSavingLog = false
    @State private var weightFieldText = ""
    @FocusState private var weightFieldFocused: Bool

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: WeightTrackingViewModel(userId: userId))
    }

    /// Trakkit weight tracker tokens (Figma)
    private let orange = Color(hex: "#EE8924")
    private let goalBlue = Color(hex: "#5D6CF3")
    private let idealGreen = Color(hex: "#479F61")
    private let screenBackground = Color(hex: "#F2F2F2")
    private let coachingTitlePurple = Color(hex: "#5E5CE6")

    var body: some View {
        rootZStack
            .navigationBarHidden(true)
            .task {
                await viewModel.load()
            }
            .onChange(of: viewModel.rulerValue) { _, _ in
                if !weightFieldFocused && !viewModel.isEmptyTrackingState {
                    syncWeightFieldFromViewModel()
                }
                if !viewModel.isEmptyTrackingState {
                    viewModel.schedulePersistWeight()
                }
            }
            .onChange(of: viewModel.displayUnit) { old, new in
                viewModel.applyUnitChange(from: old, to: new)
                syncWeightFieldFromViewModel()
            }
            .sheet(isPresented: $showGoalSheet) {
                goalSheet
            }
    }

    private var rootZStack: some View {
        ZStack {
            screenBackground.ignoresSafeArea()
            if viewModel.isLoading {
                ProgressView()
            } else if let err = viewModel.errorMessage {
                LoadFailureFallbackView(
                    message: err,
                    onRetry: { Task { await viewModel.load() } },
                    onGoBack: { dismiss() }
                )
            } else {
                loadedScroll
            }
        }
    }

    private var loadedScroll: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if viewModel.isEmptyTrackingState {
                    emptyStateContent
                } else {
                    currentWeightSection
                    progressSection
                    coachingInsightCard
                    newMilestoneCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Empty state (new user)

    private var emptyStateContent: some View {
        VStack(spacing: 20) {
            emptyCurrentWeightSection
            newMilestoneCard
            auraEmptyWeightCard
        }
    }

    private var emptyCurrentWeightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Weight")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    Text(viewModel.emptyDisplayWeightText)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .monospacedDigit()
                    Spacer(minLength: 12)
                    emptyUnitPill
                }

                WeightTrackerCardRulerView(
                    value: $viewModel.rulerValue,
                    unit: viewModel.displayUnit,
                    onSlideEnded: { _ in
                        viewModel.commitEmptyRulerSelection()
                    }
                )
                .padding(.horizontal, -4)

                HStack {
                    Spacer()
                    Button {
                        HapticFeedback.impact()
                        Task {
                            isSavingLog = true
                            await viewModel.addLogNow()
                            isSavingLog = false
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isSavingLog {
                                ProgressView()
                                    .scaleEffect(0.85)
                            }
                            Text("Add First log")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(orange)
                    }
                    .disabled(isSavingLog)
                }
            }
            .padding(18)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
    }

    private var auraEmptyWeightCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppConstants.TrakkitAI.iconBox)
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("AURA says")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitAI.title)
                Text("Tracking consistently helps you see real progress overtime.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppConstants.TrakkitAI.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    AppConstants.TrakkitAI.rowGradientTop,
                    AppConstants.TrakkitAI.cardFill
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppConstants.TrakkitAI.cardBorder.opacity(0.85), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// KG/LB toggle styled like the empty-state Figma (orange rounded rect on KG).
    private var emptyUnitPill: some View {
        HStack(spacing: 2) {
            ForEach(WeightUnit.allCases, id: \.self) { u in
                let on = viewModel.displayUnit == u
                Button {
                    viewModel.displayUnit = u
                } label: {
                    Text(u == .kg ? "KG" : "LB")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(on ? .white : Color(hex: "#8E8E93"))
                        .frame(width: 44, height: 32)
                        .background(
                            Group {
                                if on {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(orange)
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color(hex: "#E5E5EA"))
        .clipShape(Capsule())
    }

    private var goalSheet: some View {
        WeightGoalEditSheet(
            unit: viewModel.displayUnit,
            initialKg: viewModel.goalWeightKg,
            onSave: { kg in
                Task {
                    await viewModel.saveGoalKg(kg)
                    await MainActor.run { showGoalSheet = false }
                }
            },
            onCancel: { showGoalSheet = false }
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            Spacer()
            Text("Weight Tracker")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            Spacer()
            Color.clear.frame(width: 72, height: 1)
        }
        .padding(.top, 8)
    }

    // MARK: - Current weight

    private var currentWeightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Current Weight")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            currentWeightCard
        }
    }

    private var currentWeightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", viewModel.rulerValue))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                Spacer(minLength: 12)
                unitPill
            }

            weightManualInputRow

            HStack {
                Spacer()
                Button {
                    HapticFeedback.impact()
                    Task {
                        isSavingLog = true
                        await viewModel.addLogNow()
                        isSavingLog = false
                    }
                } label: {
                    HStack(spacing: 4) {
                        if isSavingLog {
                            ProgressView()
                                .scaleEffect(0.85)
                        }
                        Text("Add New log")
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(orange)
                }
                .disabled(isSavingLog)
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .onAppear {
            syncWeightFieldFromViewModel()
        }
    }

    /// Manual entry replaces the horizontal ruler (avoids overlapping / garbled tick labels).
    private var weightManualInputRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter weight")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#8E8E93"))

            TextField(
                viewModel.displayUnit == .kg ? "e.g. 72.5" : "e.g. 160",
                text: $weightFieldText
            )
            .focused($weightFieldFocused)
            .keyboardType(.decimalPad)
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(Color(hex: "#1C1C1E"))
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color(hex: "#F2F2F7"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onChange(of: weightFieldText) { _, raw in
                let filtered = Self.filterWeightInput(raw, unit: viewModel.displayUnit)
                if filtered != raw {
                    weightFieldText = filtered
                    return
                }
                if let v = Self.parseWeightDisplay(filtered, unit: viewModel.displayUnit) {
                    let r = viewModel.displayUnit.range
                    viewModel.rulerValue = min(max(v, r.lowerBound), r.upperBound)
                }
            }
            .onSubmit {
                syncWeightFieldFromViewModel()
            }
        }
    }

    private func syncWeightFieldFromViewModel() {
        weightFieldText = Self.formatWeightField(viewModel.rulerValue, unit: viewModel.displayUnit)
    }

    private static func formatWeightField(_ value: Double, unit: WeightUnit) -> String {
        String(format: "%.1f", value)
    }

    private static func filterWeightInput(_ raw: String, unit: WeightUnit) -> String {
        let s = raw.replacingOccurrences(of: ",", with: ".").filter { $0.isNumber || $0 == "." }
        guard let dot = s.firstIndex(of: ".") else {
            return String(s.prefix(unit == .kg ? 5 : 6))
        }
        let head = s[..<dot].prefix(unit == .kg ? 4 : 5)
        let fracDigits = s[s.index(after: dot)...].filter(\.isNumber)
        let frac = fracDigits.prefix(1)
        return String(head) + "." + String(frac)
    }

    private static func parseWeightDisplay(_ text: String, unit: WeightUnit) -> Double? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, t != "." else { return nil }
        return Double(t)
    }

    private var unitPill: some View {
        HStack(spacing: 4) {
            ForEach(WeightUnit.allCases, id: \.self) { u in
                let on = viewModel.displayUnit == u
                Button {
                    viewModel.displayUnit = u
                } label: {
                    ZStack {
                        if on {
                            Circle()
                                .fill(orange)
                                .frame(width: 36, height: 36)
                        }
                        Text(u == .kg ? "KG" : "LB")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(on ? .white : Color(hex: "#8E8E93"))
                    }
                    .frame(width: 40, height: 36)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: "#E5E5EA"))
        .clipShape(Capsule())
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    Text("Last 6 Months")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                Spacer()
                Text(trendLabel)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(trendColor)
            }

            progressCard
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            progressTabs

            Group {
                switch progressTab {
                case .weight:
                    weightBarChart
                        .frame(height: 300)
                case .bmr, .bodyFat:
                    Text("Insights for \(progressTab.title) will appear here as you log more data.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8E8E93"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var trendLabel: String {
        let u = viewModel.displayUnit
        let deltaKg = viewModel.trendDeltaKg
        /// Treat tiny drift as stable so the header matches a flat chart (not a misleading “0.0LB”).
        if abs(deltaKg) < 0.05 {
            return "Stable"
        }
        let v = WeightUnit.kg.convert(deltaKg, to: u)
        let absStr = String(format: "%.1f", abs(v))
        let unitStr = u == .kg ? "KG" : "LB"
        if v < 0 {
            return "- \(absStr) \(unitStr)"
        }
        return "+ \(absStr) \(unitStr)"
    }

    private var trendColor: Color {
        let deltaKg = viewModel.trendDeltaKg
        if abs(deltaKg) < 0.05 { return Color(hex: "#8E8E93") }
        let u = viewModel.displayUnit
        let v = WeightUnit.kg.convert(deltaKg, to: u)
        if v < 0 { return idealGreen }
        return Color(hex: "#FF3B30")
    }

    private var progressTabs: some View {
        HStack(spacing: 8) {
            ForEach(ProgressMetric.allCases) { tab in
                Button {
                    progressTab = tab
                    HapticFeedback.impact()
                } label: {
                    Text(tab.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(progressTab == tab ? .white : Color(hex: "#636366"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(progressTab == tab ? orange : Color(hex: "#E8E8ED"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var weightBarChart: some View {
        WeightProgressBarBlock(
            viewModel: viewModel,
            orange: orange,
            goalBlue: goalBlue,
            idealGreen: idealGreen
        )
    }

    // MARK: - Coaching

    private var coachingInsightCard: some View {
        CoachingInsightCardView(titleColor: coachingTitlePurple)
    }

    // MARK: - Milestone

    private var newMilestoneCard: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("dumble")
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("New Milestone?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                Text("Define your next transformation goal to keep the momentum going.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#8E8E93"))
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Button {
                        HapticFeedback.impact()
                        showGoalSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Add Goal")
                                .font(.system(size: 15, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(orange)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "#E5E5EA"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Progress bar chart (isolated to speed up type checking)

private struct WeightProgressBarBlock: View {
    @ObservedObject var viewModel: WeightTrackingViewModel
    var orange: Color
    var goalBlue: Color
    var idealGreen: Color

    private var barGray: Color { Color(hex: "#D8D8DC") }

    var body: some View {
        barBlockContent()
    }

    private func barBlockContent() -> some View {
        let bars = viewModel.sixMonthBars()
        let u = viewModel.displayUnit
        let unitStr = u == .kg ? "KG" : "LB"
        let lastLabel = bars.last?.label
        let yScale = yDomain(
            bars: bars,
            unit: u,
            goalKg: viewModel.goalWeightKg,
            idealKg: viewModel.idealWeightKg
        )
        return VStack(alignment: .trailing, spacing: 8) {
            legendPillsRow(unit: u, unitStr: unitStr)
            WeightBarMarksChart(
                bars: bars,
                unit: u,
                unitStr: unitStr,
                lastLabel: lastLabel,
                yScale: yScale,
                goalKg: viewModel.goalWeightKg,
                idealKg: viewModel.idealWeightKg,
                orange: orange,
                goalBlue: goalBlue,
                idealGreen: idealGreen,
                barGray: barGray
            )
        }
    }

    @ViewBuilder
    private func legendPillsRow(unit: WeightUnit, unitStr: String) -> some View {
        HStack {
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: 6) {
                if let idealKg = viewModel.idealWeightKg {
                    goalPill(
                        title: "IDEAL",
                        value: WeightUnit.kg.convert(idealKg, to: unit),
                        unitStr: unitStr,
                        fill: idealGreen
                    )
                }
                if let g = viewModel.goalWeightKg {
                    goalPill(
                        title: "GOAL",
                        value: WeightUnit.kg.convert(g, to: unit),
                        unitStr: unitStr,
                        fill: goalBlue
                    )
                }
            }
        }
    }

    private func goalPill(title: String, value: Double, unitStr: String, fill: Color) -> some View {
        Text("\(title) \(String(format: "%.0f", value)) \(unitStr)")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(fill)
            .clipShape(Capsule())
    }

    private func yDomain(
        bars: [WeightMonthBar],
        unit: WeightUnit,
        goalKg: Double?,
        idealKg: Double?
    ) -> ClosedRange<Double> {
        let values = bars.map { WeightUnit.kg.convert($0.weightKg, to: unit) }
        var lo = values.min() ?? 0
        var hi = values.max() ?? 1
        if let g = goalKg {
            let gd = WeightUnit.kg.convert(g, to: unit)
            lo = min(lo, gd)
            hi = max(hi, gd)
        }
        if let id = idealKg {
            let idd = WeightUnit.kg.convert(id, to: unit)
            lo = min(lo, idd)
            hi = max(hi, idd)
        }
        let pad = max((hi - lo) * 0.12, unit == .kg ? 0.45 : 1.0)
        var lower = lo - pad
        var upper = hi + pad

        // Flat series: widen Y band so the plot breathes and tiny differences aren’t lost at the top edge.
        let minBand: Double = unit == .kg ? 5.0 : 14.0
        if upper - lower < minBand {
            let mid = (upper + lower) / 2
            lower = mid - minBand / 2
            upper = mid + minBand / 2
        }

        return lower...upper
    }
}

private struct WeightBarMarksChart: View {
    let bars: [WeightMonthBar]
    let unit: WeightUnit
    let unitStr: String
    let lastLabel: String?
    let yScale: ClosedRange<Double>
    let goalKg: Double?
    let idealKg: Double?
    var orange: Color
    var goalBlue: Color
    var idealGreen: Color
    var barGray: Color

    private var lastId: String? { bars.last?.id }

    var body: some View {
        Chart {
            if let g = goalKg {
                RuleMark(y: .value("Goal", WeightUnit.kg.convert(g, to: unit)))
                    .foregroundStyle(goalBlue)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
            if let ideal = idealKg {
                RuleMark(y: .value("Ideal", WeightUnit.kg.convert(ideal, to: unit)))
                    .foregroundStyle(idealGreen)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
            ForEach(bars) { bar in
                let yEnd = WeightUnit.kg.convert(bar.weightKg, to: unit)
                BarMark(
                    x: .value("Month", bar.label),
                    yStart: .value("Base", yScale.lowerBound),
                    yEnd: .value("W", yEnd),
                    width: .ratio(0.44)
                )
                .foregroundStyle(bar.id == lastId ? orange : barGray)
                .cornerRadius(4)
                // Subtle nudge: categorical bars sit slightly right of axis labels on some layouts.
                .offset(x: -3)
                .annotation(position: .top, alignment: .center) {
                    if bar.id == lastId {
                        LastBarTooltip(y: yEnd, unitStr: unitStr)
                    }
                }
            }
        }
        .chartPlotStyle { plot in
            // Extra bottom inset keeps bar bases above the month labels (avoids overlap/clipping).
            plot.padding(EdgeInsets(top: 12, leading: 6, bottom: 52, trailing: 10))
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .automatic) { value in
                AxisTick(length: 0)
                AxisValueLabel(centered: true) {
                    if let s = value.as(String.self) {
                        Text(s)
                            .font(.system(size: 10, weight: (s == lastLabel) ? .bold : .medium))
                            .foregroundStyle((s == lastLabel) ? Color(hex: "#1C1C1E") : Color(hex: "#8E8E93"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.top, 14)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(hex: "#C7C7CC").opacity(0.55))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#8E8E93"))
            }
        }
        .chartYScale(domain: yScale)
    }
}

private struct LastBarTooltip: View {
    let y: Double
    let unitStr: String

    var body: some View {
        VStack(spacing: 0) {
            Text("\(String(format: "%.1f", y)) \(unitStr)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(hex: "#1C1C1E"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Rectangle()
                .fill(Color.black)
                .frame(width: 1, height: 10)
        }
    }
}

// MARK: - Coaching (isolated for type check)

private struct CoachingInsightCardView: View {
    var titleColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#AF52DE"), Color(hex: "#5E5CE6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Coaching Insight")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(titleColor)
                insightBody
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "#F3EEFF"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "#E0D4FF"), lineWidth: 1)
        )
    }

    private var insightBody: some View {
        (Text("You're making great progress towards your milestone! Remember, ")
            .foregroundColor(Color(hex: "#1C1C1E")) +
         Text("a healthy rate of weight loss is 0.5 to 1 kg (1-2 lbs) per week")
            .foregroundColor(titleColor)
            .fontWeight(.bold) +
         Text(" to ensure long-term sustainability and muscle preservation.")
            .foregroundColor(Color(hex: "#1C1C1E")))
            .font(.system(size: 14, weight: .regular))
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Progress tab

private enum ProgressMetric: String, CaseIterable, Identifiable {
    case weight
    case bmr
    case bodyFat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weight: return "Weight"
        case .bmr: return "BMR"
        case .bodyFat: return "Body Fat%"
        }
    }
}

// MARK: - Goal sheet

private struct WeightGoalEditSheet: View {
    let unit: WeightUnit
    let initialKg: Double?
    let onSave: (Double) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Target weight (\(unit.rawValue))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#8E8E93"))

                TextField("e.g. 72", text: $text)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 22, weight: .semibold))
                    .padding()
                    .background(Color(hex: "#F2F2F7"))
                    .cornerRadius(12)
                    .focused($focused)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Weight goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let v = Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
                        guard v > 0 else { return }
                        let kg = unit.convert(v, to: .kg)
                        onSave(kg)
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let kg = initialKg, kg > 0 {
                    text = String(format: "%.0f", WeightUnit.kg.convert(kg, to: unit))
                }
                focused = true
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    WeightTrackingView(userId: "preview")
}
