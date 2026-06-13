import SwiftUI

struct DailyTrackerCardView: View {
    let dailyMetrics: DailyMetrics
    let previousDayWeight: Double?
    let isFirstTimeUser: Bool
    let onWeightTap: (() -> Void)?
    let onWaterTap: (() -> Void)?
    let onStepsTap: (() -> Void)?
    let onSleepTap: (() -> Void)?

    @State private var showStartJourneyPrompt = false

    init(
        dailyMetrics: DailyMetrics,
        previousDayWeight: Double? = nil,
        isFirstTimeUser: Bool = false,
        onWeightTap: (() -> Void)? = nil,
        onWaterTap: (() -> Void)? = nil,
        onStepsTap: (() -> Void)? = nil,
        onSleepTap: (() -> Void)? = nil
    ) {
        self.dailyMetrics = dailyMetrics
        self.previousDayWeight = previousDayWeight
        self.isFirstTimeUser = isFirstTimeUser
        self.onWeightTap = onWeightTap
        self.onWaterTap = onWaterTap
        self.onStepsTap = onStepsTap
        self.onSleepTap = onSleepTap
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    /// New-home layout: a tile is “empty” until there is a goal or a logged value for that metric.
    private var waterHasTrackableData: Bool {
        dailyMetrics.water.goal > 0 || dailyMetrics.water.current > 0
    }

    private var sleepHasTrackableData: Bool {
        dailyMetrics.sleep.goal > 0 || dailyMetrics.sleep.current > 0
    }

    private var stepsHasTrackableData: Bool {
        dailyMetrics.steps.goal > 0 || dailyMetrics.steps.current > 0
    }

    private var weightHasTrackableData: Bool {
        dailyMetrics.weight.current > 0 || dailyMetrics.weight.target > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Tracker")
                .font(.system(size: isFirstTimeUser ? 19 : 20, weight: .bold))
                .foregroundColor(AppConstants.TrakkitHome.heading)
                .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 12) {
                Button {
                    handleWaterTap()
                } label: {
                    trackerMiniCard(
                        assetImageName: "drop",
                        systemIconName: nil,
                        accent: Color(hex: "#007AFF"),
                        analytics: waterPercentLine,
                        mainLine: waterMainLine,
                        caption: "Glasses of water",
                        emptyPlaceholderOnly: isFirstTimeUser && !waterHasTrackableData
                    )
                }
                .buttonStyle(.plain)
                .opacity(cardOpacity(hasData: waterHasTrackableData))

                Button {
                    handleSleepTap()
                } label: {
                    trackerMiniCard(
                        assetImageName: nil,
                        systemIconName: "moon.fill",
                        accent: Color(hex: "#AF52DE"),
                        analytics: sleepQualitativeLine,
                        mainLine: sleepDurationString(dailyMetrics.sleep.current),
                        caption: "Deep sleep cycle",
                        emptyPlaceholderOnly: isFirstTimeUser && !sleepHasTrackableData
                    )
                }
                .buttonStyle(.plain)
                .opacity(cardOpacity(hasData: sleepHasTrackableData))

                Button {
                    handleStepsTap()
                } label: {
                    trackerMiniCard(
                        assetImageName: "shoe",
                        systemIconName: nil,
                        accent: AppConstants.TrakkitHome.accentOrange,
                        analytics: stepsAbbreviated,
                        mainLine: stepsFormattedInteger,
                        caption: "Steps today",
                        emptyPlaceholderOnly: isFirstTimeUser && !stepsHasTrackableData
                    )
                }
                .buttonStyle(.plain)
                .opacity(cardOpacity(hasData: stepsHasTrackableData))

                Button {
                    handleWeightTap()
                } label: {
                    trackerMiniCard(
                        assetImageName: "weight",
                        systemIconName: nil,
                        accent: Color(hex: "#34C759"),
                        analytics: weightDeltaLine,
                        mainLine: weightMainLine,
                        caption: "Body weight",
                        emptyPlaceholderOnly: isFirstTimeUser && !weightHasTrackableData
                    )
                }
                .buttonStyle(.plain)
                .opacity(cardOpacity(hasData: weightHasTrackableData))
            }
            .padding(.horizontal, 20)
        }
        .alert("Start your journey", isPresented: $showStartJourneyPrompt) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please start your journey and add your goals. Schedule a workout or set up trackers from your profile, then you can open each tracker from here.")
        }
    }

    private func cardOpacity(hasData: Bool) -> Double {
        isFirstTimeUser && !hasData ? 0.88 : 1.0
    }

    private func handleWaterTap() {
        onWaterTap?()
    }

    private func handleSleepTap() {
        onSleepTap?()
    }

    private func handleStepsTap() {
        onStepsTap?()
    }

    private func handleWeightTap() {
        onWeightTap?()
    }

    private var waterPercentLine: String {
        let pct = Int(dailyMetrics.water.progress * 100)
        return dailyMetrics.water.goal > 0 ? "\(pct)%" : "--"
    }

    private var waterMainLine: String {
        if dailyMetrics.water.goal <= 0 && dailyMetrics.water.current <= 0 { return "--" }
        if dailyMetrics.water.goal <= 0 { return "\(dailyMetrics.water.current)" }
        return "\(dailyMetrics.water.current)/\(dailyMetrics.water.goal)"
    }

    private var sleepQualitativeLine: String {
        let s = dailyMetrics.sleep
        if s.goal <= 0 { return "--" }
        if s.current >= s.goal * 0.95 { return "Fresh" }
        if s.current >= s.goal * 0.75 { return "Good" }
        return "Low"
    }

    private func sleepDurationString(_ hours: Double) -> String {
        if hours <= 0 { return "--" }
        let h = Int(hours)
        let m = Int(round((hours - Double(h)) * 60))
        return "\(h)h \(m)m"
    }

    private var stepsAbbreviated: String {
        let n = dailyMetrics.steps.current
        if n >= 1000 {
            return String(format: "%.1fk", Double(n) / 1000.0)
        }
        return "\(n)"
    }

    private var stepsFormattedInteger: String {
        let n = dailyMetrics.steps.current
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private var weightDeltaLine: String {
        guard let prev = previousDayWeight, dailyMetrics.weight.current > 0 else {
            return "--"
        }
        let delta = dailyMetrics.weight.current - prev
        if abs(delta) < 0.05 { return "0 kg" }
        let sign = delta > 0 ? "+" : ""
        return String(format: "%@%.1f kg", sign, delta)
    }

    private var weightMainLine: String {
        if dailyMetrics.weight.current <= 0 { return "--" }
        return String(format: "%.1fkg", dailyMetrics.weight.current)
    }

    private func trackerMiniCard(
        assetImageName: String?,
        systemIconName: String?,
        accent: Color,
        analytics: String,
        mainLine: String,
        caption: String,
        emptyPlaceholderOnly: Bool
    ) -> some View {
        Group {
            if emptyPlaceholderOnly {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.16))
                                .frame(width: 44, height: 44)
                            trackerIconView(assetImageName: assetImageName, systemIconName: systemIconName, accent: accent)
                        }
                        Spacer(minLength: 0)
                    }

                    Text("--")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)

                    Text(caption)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous))
                .shadow(
                    color: AppConstants.TrakkitHome.cardShadowColor,
                    radius: AppConstants.TrakkitHome.cardShadowRadius,
                    x: 0,
                    y: AppConstants.TrakkitHome.cardShadowY
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(accent.opacity(0.16))
                                .frame(width: 44, height: 44)
                            trackerIconView(assetImageName: assetImageName, systemIconName: systemIconName, accent: accent)
                        }

                        Spacer(minLength: 8)

                        Text(analytics)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(accent)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }

                    Text(mainLine)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppConstants.TrakkitHome.heading)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    Text(caption)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppConstants.TrakkitHome.secondaryText)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous))
                .shadow(
                    color: AppConstants.TrakkitHome.cardShadowColor,
                    radius: AppConstants.TrakkitHome.cardShadowRadius,
                    x: 0,
                    y: AppConstants.TrakkitHome.cardShadowY
                )
            }
        }
    }

    @ViewBuilder
    private func trackerIconView(assetImageName: String?, systemIconName: String?, accent: Color) -> some View {
        if let name = assetImageName {
            Image(name)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 24, height: 24)
        } else if let system = systemIconName {
            Image(systemName: system)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(accent)
        }
    }
}

#Preview {
    DailyTrackerCardView(
        dailyMetrics: DashboardViewModel2.generateMockDailyMetrics(),
        previousDayWeight: 72.9
    )
    .background(AppConstants.TrakkitHome.background)
    .previewLayout(.sizeThatFits)
}
