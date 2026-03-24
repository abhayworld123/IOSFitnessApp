import SwiftUI
import Charts

struct WeightTrackingView: View {
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WeightTrackingViewModel
    @State private var showGoalSheet = false

    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: WeightTrackingViewModel(userId: userId))
    }

    var body: some View {
        ZStack {
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        header

                        currentWeightCard

                        logSection

                        addGoalCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.rulerValue) { _, _ in
            viewModel.schedulePersistWeight()
        }
        .onChange(of: viewModel.displayUnit) { old, new in
            viewModel.applyUnitChange(from: old, to: new)
        }
        .sheet(isPresented: $showGoalSheet) {
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

    private var currentWeightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Current Weight")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            WeightRulerView(selectedWeight: $viewModel.rulerValue, unit: viewModel.displayUnit)

            HStack(alignment: .center) {
                UnitSelectorView(selectedUnit: $viewModel.displayUnit)
                Spacer()
                Text(String(format: "%.0f", viewModel.rulerValue))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "#2C2C2E"))
                    .frame(minWidth: 88)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(14)
            }
        }
        .padding(18)
        .background(Color(hex: "#E8E8ED"))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Log chart

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            VStack(alignment: .leading, spacing: 12) {
                if chartPoints.isEmpty {
                    Text("Log your weight to see your trend here.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#8E8E93"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    weightChart
                        .frame(height: 220)

                    legendRow
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private var chartPoints: [WeightChartPoint] {
        viewModel.history.map { entry in
            WeightChartPoint(
                date: entry.date,
                yDisplay: WeightUnit.kg.convert(entry.weightKg, to: viewModel.displayUnit)
            )
        }
    }

    private var chartDateBounds: (Date, Date) {
        let cal = Calendar.current
        let now = Date()
        guard let first = chartPoints.map(\.date).min(),
              let last = chartPoints.map(\.date).max() else {
            let start = cal.date(byAdding: .day, value: -30, to: now) ?? now
            return (start, now)
        }
        let padStart = cal.date(byAdding: .day, value: -2, to: first) ?? first
        let padEnd = cal.date(byAdding: .day, value: 2, to: max(last, now)) ?? now
        return (padStart, padEnd)
    }

    private var weightChart: some View {
        let bounds = chartDateBounds
        let unitLabel = viewModel.displayUnit.rawValue
        let orange = Color(hex: "#FF9500")

        return Chart {
            if let band = viewModel.idealBandKg, viewModel.goalWeightKg != nil {
                let yLow = WeightUnit.kg.convert(band.low, to: viewModel.displayUnit)
                let yHigh = WeightUnit.kg.convert(band.high, to: viewModel.displayUnit)
                RectangleMark(
                    xStart: .value("r0", bounds.0),
                    xEnd: .value("r1", bounds.1),
                    yStart: .value("idealLo", min(yLow, yHigh)),
                    yEnd: .value("idealHi", max(yLow, yHigh))
                )
                .foregroundStyle(orange.opacity(0.14))
            }

            if let g = viewModel.goalWeightKg {
                let yGoal = WeightUnit.kg.convert(g, to: viewModel.displayUnit)
                RuleMark(y: .value("Goal", yGoal))
                    .foregroundStyle(orange)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }

            ForEach(chartPoints) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Weight", p.yDisplay)
                )
                .foregroundStyle(orange)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .interpolationMethod(.linear)

                PointMark(
                    x: .value("Date", p.date),
                    y: .value("Weight", p.yDisplay)
                )
                .foregroundStyle(orange)
                .symbol(.square)
                .symbolSize(36)
                .annotation(position: .top, spacing: 6) {
                    if p.id == chartPoints.last?.id {
                        VStack(spacing: 2) {
                            Text("\(Int(round(p.yDisplay))) \(unitLabel)")
                                .font(.system(size: 12, weight: .semibold))
                            Text(p.date, format: .dateTime.day().month(.abbreviated).year(.twoDigits))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#8E8E93"))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(hex: "#C7C7CC"))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .foregroundStyle(Color(hex: "#8E8E93"))
                    .font(.system(size: 10))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color(hex: "#C7C7CC").opacity(0.6))
                AxisValueLabel()
                    .foregroundStyle(Color(hex: "#8E8E93"))
                    .font(.system(size: 10))
            }
        }
        .chartYScale(domain: yAxisDomain)
    }

    private var yAxisDomain: ClosedRange<Double> {
        let values = chartPoints.map(\.yDisplay)
        var lo = values.min() ?? viewModel.rulerValue
        var hi = values.max() ?? viewModel.rulerValue
        if let g = viewModel.goalWeightKg {
            let gd = WeightUnit.kg.convert(g, to: viewModel.displayUnit)
            lo = min(lo, gd)
            hi = max(hi, gd)
        }
        if let band = viewModel.idealBandKg {
            let a = WeightUnit.kg.convert(band.low, to: viewModel.displayUnit)
            let b = WeightUnit.kg.convert(band.high, to: viewModel.displayUnit)
            lo = min(lo, a, b)
            hi = max(hi, a, b)
        }
        let pad = max((hi - lo) * 0.12, 2.0)
        return (lo - pad)...(hi + pad)
    }

    private var legendRow: some View {
        HStack(spacing: 20) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#FF9500").opacity(0.25))
                    .frame(width: 18, height: 10)
                Text("Ideal Weight")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(hex: "#FF9500"))
                    .frame(width: 18, height: 3)
                Text("Goal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Add goal

    private var addGoalCard: some View {
        VStack(spacing: 12) {
            Button(action: {
                showGoalSheet = true
                HapticFeedback.impact()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            Text("Add Goal")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            Text("Add your weight goals here")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "#8E8E93"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Chart model

private struct WeightChartPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let yDisplay: Double
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
