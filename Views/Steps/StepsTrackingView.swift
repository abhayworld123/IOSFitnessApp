import SwiftUI

struct StepsTrackingView: View {
    let userId: String
    let stepsMetric: StepsMetric
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: StepsTrackingViewModel
    @State private var showEditGoal = false
    @State private var editGoalText = ""
    @State private var showManualLogSheet = false
    @State private var manualSteps = 5000

    init(userId: String, stepsMetric: StepsMetric) {
        self.userId = userId
        self.stepsMetric = stepsMetric
        _viewModel = StateObject(wrappedValue: StepsTrackingViewModel(userId: userId, stepsMetric: stepsMetric))
    }

    private let screenBg = Color(hex: "#F2F2F2")
    private let accentOrange = Color(hex: "#EE8924")

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        navigationHeader

                        if viewModel.isEmptyTrackingState {
                            emptyStateContent
                        } else {
                            trackingStateContent
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            if viewModel.healthStatus == .authorized {
                await viewModel.loadTodayStepsFromHealth()
            } else {
                await viewModel.loadData()
            }
        }
        .onChange(of: viewModel.needsGoalSetup) { _, need in
            if need && !viewModel.isLoading && !viewModel.isEmptyTrackingState {
                editGoalText = viewModel.stepsGoal > 0 ? "\(viewModel.stepsGoal)" : "10000"
                showEditGoal = true
            }
        }
        .sheet(isPresented: $showManualLogSheet) {
            manualLogSheet
        }
        .alert("Edit Steps Goal", isPresented: $showEditGoal) {
            TextField("Goal (e.g. 10000)", text: $editGoalText)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let value = Int(editGoalText), value > 0 {
                    viewModel.updateStepsGoal(value)
                }
            }
        } message: {
            Text("Enter your daily steps goal.")
        }
        .alert("Steps", isPresented: Binding(
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
        VStack(spacing: 18) {
            readyRingHero
            emptyActionButtons
            emptyConnectedDeviceCard
            auraEmptyStepsCard
            reminderCard
        }
    }

    private var readyRingHero: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 214, height: 214)

            Circle()
                .stroke(Color(hex: "#E5E5EA"), lineWidth: 16)
                .frame(width: 188, height: 188)

            Circle()
                .fill(Color.white)
                .frame(width: 118, height: 118)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

            VStack(spacing: 8) {
                Image("shoe")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(accentOrange)

                Text("READY")
                    .font(.system(size: 13, weight: .heavy))
                    .kerning(1.2)
                    .foregroundColor(accentOrange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var emptyActionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.connectDevice() }
            } label: {
                Group {
                    if viewModel.isHealthLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Connect Device")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentOrange)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(viewModel.isHealthLoading)

            Button {
                showManualLogSheet = true
            } label: {
                Text("Log steps manually")
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
                .disabled(viewModel.isHealthLoading)
            }
            .padding(.vertical, 14)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var auraEmptyStepsCard: some View {
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
                Text("“Walking is the foundation of metabolic health. Let’s get your data synced to find your baseline.”")
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
                    Stepper(value: $manualSteps, in: 0...50_000, step: 500) {
                        HStack {
                            Text("Steps today")
                            Spacer()
                            Text("\(manualSteps.formatted())")
                                .foregroundColor(Color(hex: "#8E8E93"))
                                .monospacedDigit()
                        }
                    }
                } footer: {
                    Text("Log your step count for today.")
                }
            }
            .navigationTitle("Log Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showManualLogSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        showManualLogSheet = false
                        Task { await viewModel.logManualSteps(manualSteps) }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Active tracking state

    private var trackingStateContent: some View {
        VStack(spacing: 24) {
            summaryCardsRow
            connectedDeviceCard
            dailyActivityCard
            reminderCard
        }
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(Color(hex: "#1C1C1E"))
            }

            Spacer()

            Text("Steps")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            Spacer()

            Color.clear
                .frame(width: 60, height: 24)
        }
        .padding(.top, 4)
    }

    // MARK: - Summary Cards (Steps + Distance)

    private var summaryCardsRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#AF52DE").opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: "#AF52DE"))
                    }
                    Text("Steps")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    Spacer()
                    Button(action: {
                        editGoalText = "\(viewModel.stepsGoal)"
                        showEditGoal = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#1C1C1E"))
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(viewModel.steps.formatted())")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    Text("/\(viewModel.stepsGoal.formatted())")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#34C759").opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "location.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#34C759"))
                    }
                    Text("Distance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                }
                Text(viewModel.formattedDistance)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Connected Device/App Card

    private var connectedDeviceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connected Device/App")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            HStack {
                Text("Connect a Device/App")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                Spacer()
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 4)

            Divider()
                .background(Color(hex: "#E5E5EA"))

            appleHealthRow
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var appleHealthRow: some View {
        let isConnected = viewModel.healthStatus == .authorized
        let canConnect = viewModel.healthStatus == .unknown || viewModel.healthStatus == .notDetermined
        let isUnavailable = viewModel.healthStatus == .notAvailable
        let isDenied = viewModel.healthStatus == .denied
        let hasError = viewModel.healthStatus.isError

        return HStack(alignment: .center) {
            Image(systemName: "heart.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "#FF3B30"))
            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Health")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                Text(appleHealthSubtitle(
                    isConnected: isConnected,
                    canConnect: canConnect,
                    isUnavailable: isUnavailable,
                    isDenied: isDenied,
                    hasError: hasError
                ))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(hex: "#8E8E93"))
            }
            Spacer()
            if viewModel.isHealthLoading {
                ProgressView()
                    .scaleEffect(0.9)
            } else if isConnected {
                Button(action: {
                    Task { await viewModel.loadTodayStepsFromHealth() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#007AFF"))
                }
                .buttonStyle(.plain)
            } else if canConnect || isDenied || hasError {
                Button(action: {
                    Task { await viewModel.connectDevice() }
                }) {
                    Text("Connect")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#007AFF"))
                }
                .buttonStyle(.plain)
                .disabled(isUnavailable)
            }
        }
        .padding(.vertical, 4)
    }

    private func appleHealthSubtitle(
        isConnected: Bool,
        canConnect: Bool,
        isUnavailable: Bool,
        isDenied: Bool,
        hasError: Bool
    ) -> String {
        if viewModel.isHealthLoading {
            return "Connecting…"
        }
        if isConnected {
            return viewModel.lastSyncedText
        }
        if isUnavailable {
            return "Health is not available on this device."
        }
        if isDenied {
            return "Access denied. Tap Connect to try again or open Settings."
        }
        if hasError {
            return "Something went wrong. Tap Connect to try again."
        }
        if canConnect {
            return "Tap Connect to use your step count from Apple Health."
        }
        return viewModel.lastSyncedText
    }

    // MARK: - Daily Activity Chart Card

    private var dailyActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }

            stepsBarChart
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var stepsBarChart: some View {
        let labels = ["12 AM", "6", "12 PM", "6"]
        let maxY: Int = 4000
        let maxValue = max(maxY, viewModel.hourlySteps.max() ?? 1)
        let chartHeight: CGFloat = 120

        return VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(viewModel.hourlySteps.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentOrange)
                            .frame(height: max(CGFloat(value) / CGFloat(maxValue) * chartHeight, 4))
                        Text(labels[index])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "#8E8E93"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: chartHeight)
        }
    }

    // MARK: - Set Reminder Card

    private var reminderCard: some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel.toggleReminder()
            }) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 60, height: 60)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            VStack(spacing: 4) {
                Text("Set Reminder")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                Text("You will be notified")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Formatting

private extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

#Preview {
    StepsTrackingView(
        userId: "preview",
        stepsMetric: StepsMetric(current: 0, goal: 0)
    )
}
