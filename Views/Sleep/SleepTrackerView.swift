import SwiftUI

// Figma: https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=724-1383
/// "Today's Sleep" full-screen tracker (sleep ring, summary cards, window question, Health, insight).
struct SleepTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SleepTrackerViewModel
    @State private var showManualLogSheet = false
    @State private var manualLogHours = 7
    @State private var manualLogMinutes = 30

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: SleepTrackerViewModel(userId: userId))
    }

    private let bg = Color(hex: "#F2F2F2")
    private let trackGrey = Color(hex: "#E8E8E8")
    private let ringBlue = Color(hex: "#0A7DFF")
    private let ringAmber = Color(hex: "#FFBB5C")
    private let accentOrange = Color(hex: "#EE8924")

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if viewModel.isEmptyTrackingState {
                            emptyStateContent
                        } else {
                            trackingStateContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .task { await viewModel.load() }
        .sheet(isPresented: $showManualLogSheet) {
            manualLogSheet
        }
        .alert("Sleep", isPresented: Binding(
            get: { viewModel.deviceConnectMessage != nil },
            set: { if !$0 { viewModel.deviceConnectMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.deviceConnectMessage = nil }
        } message: {
            Text(viewModel.deviceConnectMessage ?? "")
        }
    }

    // MARK: - Empty state (new user)

    private var emptyStateContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Unlock your recovery")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .padding(.top, 4)

            emptyMainCard
            emptyConnectedDeviceCard
            auraEmptyStateCard
        }
    }

    private var emptyMainCard: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentOrange)
                    .frame(width: 56, height: 56)
                Image(systemName: "moon.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Track your sleep cycles to understand how your body recovers for peak performance.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "#636366"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.connectDevice() }
                } label: {
                    Text("Connect Device")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button {
                    showManualLogSheet = true
                } label: {
                    Text("Log sleep manually")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(hex: "#D1D1D6"), lineWidth: 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var emptyConnectedDeviceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Connected Device/App")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .padding(.bottom, 8)

            Divider().background(Color(hex: "#E5E5EA"))

            HStack {
                Text("Connect a Device/App")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#3C3C43"))
                Spacer()
                Button {
                    Task { await viewModel.connectDevice() }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(accentOrange))
                }
            }
            .padding(.vertical, 14)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var auraEmptyStateCard: some View {
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
                Text("Aura Says")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitAI.title)
                Text("Your daily readiness score combines sleep quality, HRV, and activity load to tell you exactly how hard you should push today. Connect your data to begin.")
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

    private var manualLogSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $manualLogHours, in: 0...14) {
                        HStack {
                            Text("Hours")
                            Spacer()
                            Text("\(manualLogHours)")
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                    }
                    Stepper(value: $manualLogMinutes, in: 0...59, step: 5) {
                        HStack {
                            Text("Minutes")
                            Spacer()
                            Text("\(manualLogMinutes)")
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                    }
                } footer: {
                    Text("Log how long you slept last night.")
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showManualLogSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let total = Double(manualLogHours) + Double(manualLogMinutes) / 60.0
                        showManualLogSheet = false
                        Task { await viewModel.logManualSleep(hours: total) }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Active tracking state

    private var trackingStateContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Today’s Sleep")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .padding(.horizontal, 2)

            sleepRingSection
            summaryCardsRow
            windowQuestionCard
            connectedDeviceCard
            insightCard
        }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            Spacer()
            Text("Sleep")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            Spacer()
            Color.clear.frame(width: 72, height: 1)
        }
        .padding(.top, 4)
    }

    private var sleepRingSection: some View {
        VStack(spacing: 14) {
            ZStack {
                SleepDonutRing(
                    progress: viewModel.progressTowardGoal,
                    deepFractionOfFill: viewModel.deepPortionOfFill,
                    trackColor: trackGrey,
                    deepColor: ringBlue,
                    lightColor: ringAmber,
                    lineWidth: 19
                )
                .frame(width: 220, height: 220)
                VStack(spacing: 4) {
                    Text("TIME ASLEEP")
                        .font(.system(size: 9, weight: .semibold))
                        .kerning(0.6)
                        .foregroundColor(Color(hex: "#8E8E93"))
                    Text(formatHrsMin(viewModel.asleepHours))
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    Text(viewModel.percentVsAverageLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(viewModel.percentVsAverageIsPositive ? Color(hex: "#34C759") : Color(hex: "#8E8E93"))
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryCardsRow: some View {
        HStack(spacing: 12) {
            summaryCard(
                gradient: [Color(hex: "#FFB65A"), Color(hex: "#F58A1C")],
                icon: "moon.stars.fill",
                label: "Total Sleep",
                value: formatHrsMin(viewModel.asleepHours)
            )
            summaryCard(
                gradient: [Color(hex: "#3D8BFF"), Color(hex: "#1B6AEE")],
                icon: "bed.double.fill",
                label: "Deep Sleep",
                value: String(format: "%.0f%%", viewModel.deepSleepPercent * 100)
            )
        }
    }

    private func summaryCard(gradient: [Color], icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.95))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
    }

    private var windowQuestionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DID YOU HIT YOUR WINDOW LAST NIGHT?")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                windowButton(
                    title: "YES",
                    isSelected: viewModel.hitSleepWindow == true,
                    selected: {
                        viewModel.setHitWindow(true)
                    }
                )
                windowButton(
                    title: "NO",
                    isSelected: viewModel.hitSleepWindow == false,
                    selected: {
                        viewModel.setHitWindow(false)
                    }
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private func windowButton(title: String, isSelected: Bool, selected: @escaping () -> Void) -> some View {
        let isYes = title == "YES"
        return Button(action: selected) {
            HStack {
                if isYes {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                }
                Text(title)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(isYes
                ? (isSelected ? Color(hex: "#1B7A3A") : Color(hex: "#8E8E93"))
                : (isSelected ? Color(hex: "#3C3C43") : Color(hex: "#8E8E93")))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        isYes
                            ? (isSelected ? Color(hex: "#E5F5EC") : Color(hex: "#F2F2F7"))
                            : (isSelected ? Color(hex: "#E8E8ED") : Color(hex: "#F2F2F7"))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isYes
                            ? (isSelected ? Color(hex: "#34C759") : Color.clear)
                            : (isSelected ? Color(hex: "#AEAEB2") : Color.clear),
                        lineWidth: isSelected ? 2 : 0
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var connectedDeviceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Connected Device/App")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .padding(.bottom, 2)

            HStack {
                Text("Connect a Device/App")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#3C3C43"))
                Spacer()
                Button {
                    HapticFeedback.impact(style: .light)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(hex: "#EE8924")))
                }
            }
            .padding(.vertical, 12)

            Divider().background(Color(hex: "#E5E5EA"))

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay { Image(systemName: "heart.fill").font(.system(size: 14)).foregroundColor(.white) }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Apple Health")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Sleep & activity")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                Spacer()
                Button { viewModel.markSyncNow() } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(hex: "#0A7DFF")))
                }
            }
            .padding(.vertical, 12)

            if let d = viewModel.lastSyncDate {
                Text("Last synced: \(d.formatted(.dateTime.weekday().month().day().hour().minute()))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var insightCard: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: "#8B5CF6"), Color(hex: "#5B5CE6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay { Image(systemName: "sparkles").font(.system(size: 18, weight: .semibold)).foregroundColor(.white) }
            VStack(alignment: .leading, spacing: 6) {
                Text("Insight")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#5E5CE6"))
                Text("Based on yesterday's high-intensity Leg Day, your body needs 45 mins more deep sleep tonight for optimal muscle recovery.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "#3C3C43"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: "#F3EEFF"), Color.white.opacity(0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: "#E0D4FF"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func formatHrsMin(_ h: Double) -> String {
        let total = max(0, h)
        let hours = Int(floor(total))
        let minutes = Int((total - Double(hours)) * 60.0 + 0.5)
        return "\(hours)hr \(minutes)min"
    }
}

// MARK: - Donut (multi-segment on goal progress)

private struct SleepDonutRing: View {
    let progress: Double
    let deepFractionOfFill: Double
    let trackColor: Color
    let deepColor: Color
    let lightColor: Color
    var lineWidth: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            let p = min(1, max(0, progress))
            if p > 0.0001 {
                let tBlue = p * min(1, max(0, deepFractionOfFill))
                Circle()
                    .trim(from: 0, to: tBlue)
                    .stroke(deepColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if p - tBlue > 0.0001 {
                    Circle()
                        .trim(from: tBlue, to: p)
                        .stroke(lightColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }
}

#Preview {
    SleepTrackerView(userId: "preview")
}
