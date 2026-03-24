import SwiftUI

struct StepsTrackingView: View {
    let userId: String
    let stepsMetric: StepsMetric
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: StepsTrackingViewModel
    @State private var showEditGoal = false
    @State private var editGoalText = ""

    init(userId: String, stepsMetric: StepsMetric) {
        self.userId = userId
        self.stepsMetric = stepsMetric
        _viewModel = StateObject(wrappedValue: StepsTrackingViewModel(userId: userId, stepsMetric: stepsMetric))
    }

    var body: some View {
        ZStack {
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        navigationHeader
                        summaryCardsRow
                        connectedDeviceCard
                        dailyActivityCard
                        reminderCard
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
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
            if need && !viewModel.isLoading {
                editGoalText = viewModel.stepsGoal > 0 ? "\(viewModel.stepsGoal)" : "10000"
                showEditGoal = true
            }
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))

            Spacer()

            Color.clear
                .frame(width: 60, height: 24)
        }
    }

    // MARK: - Summary Cards (Steps + Distance)

    private var summaryCardsRow: some View {
        HStack(spacing: 12) {
            // Steps card
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

            // Distance card
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

            // Connect row
            HStack {
                Text("Connect a Device/App")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: 36, height: 36)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 4)

            Divider()
                .background(Color(hex: "#E5E5EA"))

            // Apple Health row – connect or refresh
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
                    Task { await viewModel.requestHealthAuthorizationAndLoadSteps() }
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
                            .fill(Color(hex: "#FF9500"))
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
                        .fill(Color(hex: "#FF9500"))
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
        stepsMetric: StepsMetric(current: 6000, goal: 10000)
    )
}
