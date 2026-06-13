import SwiftUI

struct WaterTrackingView: View {
    let userId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WaterTrackingViewModel
    @State private var showEditGoal = false
    @State private var showReminderSheet = false
    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    private let screenBg = Color(hex: "#F2F2F2")
    private let accentBlue = Color(hex: "#6BB6FF")
    private let accentOrange = Color(hex: "#EE8924")
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: WaterTrackingViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else if let err = viewModel.errorMessage {
                LoadFailureFallbackView(
                    message: err,
                    onRetry: {
                        Task { await viewModel.loadData() }
                    },
                    onGoBack: { dismiss() }
                )
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        navigationHeader

                        if viewModel.isEmptyTrackingState {
                            emptyWaterGoalCard
                            auraEmptyStateCard
                        } else {
                            waterGoalCard
                            reminderCard
                            aiOptimizedCard
                            supplementAdviceCard
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            selectedDate = viewModel.selectedDate
            await viewModel.loadData()
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showDatePicker = false
                            viewModel.selectedDate = selectedDate
                            Task {
                                await viewModel.loadData()
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showEditGoal) {
            WaterGoalEditSheet(
                goal: viewModel.goal <= 0 ? 12 : viewModel.goal,
                glassSize: viewModel.glassSize,
                onSave: { newGoal, newGlassSize in
                    viewModel.updateGoal(newGoal)
                    viewModel.updateGlassSize(newGlassSize)
                    showEditGoal = false
                },
                onCancel: { showEditGoal = false }
            )
        }
        .sheet(isPresented: $showReminderSheet) {
            WaterReminderSheet(
                reminder: viewModel.reminder,
                onSave: { isEnabled, times in
                    Task {
                        await viewModel.saveReminderSettings(isEnabled: isEnabled, times: times)
                        await MainActor.run { showReminderSheet = false }
                    }
                },
                onCancel: { showReminderSheet = false }
            )
        }
        .overlay(alignment: .top) {
            if viewModel.showGoalReachedToast {
                goalReachedToast
            }
        }
        .onChange(of: viewModel.showGoalReachedToast) { _, show in
            if show {
                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    viewModel.clearGoalReachedToast()
                }
            }
        }
    }

    // MARK: - Goal Reached Toast

    private var goalReachedToast: some View {
        Text("Goal complete! 🎉")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "#34C759"))
            .cornerRadius(12)
            .padding(.top, 56)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.showGoalReachedToast)
    }

    // MARK: - Navigation Header

    private var navigationHeader: some View {
        VStack(spacing: 10) {
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
                .accessibilityLabel("Go back")

                Spacer()

                Text("Water")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))

                Spacer()

                Color.clear.frame(width: 72, height: 1)
            }

            Button {
                selectedDate = viewModel.selectedDate
                showDatePicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(isToday(viewModel.selectedDate) ? "Today" : formattedDate(viewModel.selectedDate))
                        .font(.system(size: 15, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(Color(hex: "#1C1C1E"))
            }
            .accessibilityLabel("Select date")
            .accessibilityHint("Opens date picker to view water intake for different days")
        }
    }

    // MARK: - Empty state (new user / no history)

    private var emptyWaterGoalCard: some View {
        let displayGoal = viewModel.displayGoal
        let glassMl = viewModel.glassSize >= 100 ? viewModel.glassSize : WaterTrackingViewModel.defaultGlassSizeMl

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Goal: \(displayGoal) Glasses")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))

                    Text("1 Glass: \(glassMl) ml")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }

                Spacer(minLength: 12)

                Button { showEditGoal = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "#F2F2F7"))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit water goal")
            }

            VStack(spacing: 16) {
                ZStack {
                    WaterProgressRing(progress: 0, diameter: 208, lineWidth: 14, fill: accentBlue)

                    VStack(spacing: 10) {
                        WaterGlassIcon(progress: 0, size: 78, showsOuterStroke: false)

                        Text("0")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Color(hex: "#1C1C1E"))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                VStack(spacing: 8) {
                    Text("Start tracking your hydration")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .multilineTextAlignment(.center)

                    Text("Stay energized and improve recovery by tracking your daily water intake")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "#8E8E93"))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 12) {
                    Button {
                        viewModel.ensureDefaultGoalIfNeeded()
                        viewModel.incrementGlass()
                    } label: {
                        Text("Drink a glass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .accessibilityLabel("Log one glass of water")

                    Button {
                        showEditGoal = true
                    } label: {
                        Text("Set daily goal")
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
                    .accessibilityLabel("Set your daily water goal")
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
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
                Text("Aura says:")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitAI.title)
                Text("“Even small sips add up. Let’s start with one glass.”")
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

    // MARK: - Water Goal Card

    private var waterGoalCard: some View {
        let ringProgress = waterRingProgress
        let consumed = viewModel.currentIntake?.glassesConsumed ?? 0
        let goal = max(viewModel.goal, 0)

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal <= 0 ? "Set your daily goal" : "Goal: \(goal) Glasses")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))

                    Text("1 Glass: \(viewModel.glassSize) ml")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }

                Spacer(minLength: 12)

                Button { showEditGoal = true } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "#F2F2F7"))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit water goal")
            }

            VStack(spacing: 14) {
                ZStack {
                    WaterProgressRing(progress: ringProgress, diameter: 208, lineWidth: 14, fill: accentBlue)

                    VStack(spacing: 10) {
                        WaterGlassIcon(
                            progress: ringProgress,
                            size: 78,
                            showsOuterStroke: false
                        )

                        if goal <= 0 {
                            Text("Tap pencil to set goal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "#8E8E93"))
                                .multilineTextAlignment(.center)
                        } else {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("\(consumed)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(Color(hex: "#1C1C1E"))
                                Text("/\(goal) glasses")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "#8E8E93"))
                            }
                            .accessibilityLabel("\(consumed) of \(goal) glasses")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                if goal > 0 {
                    Text("\(Int(round(ringProgress * 100)))% OF YOUR DAILY TARGET")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.6)
                        .foregroundColor(Color(hex: "#34C759"))
                        .frame(maxWidth: .infinity)
                }

                drinkControlsRow
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private var waterRingProgress: Double {
        guard viewModel.goal > 0 else { return 0 }
        return viewModel.currentIntake?.progress ?? 0
    }

    private var drinkControlsRow: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.decrementGlass()
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentBlue)
                    .frame(width: 52, height: 52)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(accentBlue, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled((viewModel.currentIntake?.glassesConsumed ?? 0) <= 0)
            .accessibilityLabel("Remove one glass of water")

            Button {
                if viewModel.goal <= 0 {
                    showEditGoal = true
                } else {
                    viewModel.incrementGlass()
                }
            } label: {
                Text("Drink a glass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .accessibilityLabel("Add one glass of water")
        }
    }

    // MARK: - Reminder Card

    private var reminderCard: some View {
        Button {
            showReminderSheet = true
        } label: {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accentOrange)
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Reminder")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))

                    Text(reminderSubtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set water reminders")
        .accessibilityHint("Configure when to get reminded to drink water")
    }

    // MARK: - AI suggestion (static copy; goal bump uses glass size)

    private var aiOptimizedCard: some View {
        let activityMl = 250
        let weatherMl = 100
        let totalMl = activityMl + weatherMl

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                Text("AI OPTIMIZED")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(hex: "#34C759"))
            .clipShape(Capsule())

            Text("Today's Optimal Goal")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Based on your HIIT workout and local temperature (28°C), we've adjusted your goal by +\(totalMl)mL.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .bottom, spacing: 10) {
                aiBreakdownChip(title: "Activity", value: "+\(activityMl)mL")
                aiBreakdownChip(title: "Weather", value: "+\(weatherMl)mL")
                Spacer(minLength: 8)
                Button {
                    applyAISuggestionMl(totalMl)
                } label: {
                    Text("Add to goal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(accentOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(viewModel.goal <= 0)
                .accessibilityHint("Increases your daily glass goal based on the suggestion")
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "#8B7CF8"), Color(hex: "#5E5CE6")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func aiBreakdownChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func applyAISuggestionMl(_ ml: Int) {
        guard viewModel.goal > 0 else {
            showEditGoal = true
            return
        }
        let gs = max(viewModel.glassSize, 1)
        let extraGlasses = max(1, Int(ceil(Double(ml) / Double(gs))))
        viewModel.updateGoal(viewModel.goal + extraGlasses)
    }

    private var supplementAdviceCard: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "#E8E4FF"))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#5E5CE6"))
                )

            VStack(alignment: .leading, spacing: 8) {
                Text("SUPPLEMENT ADVICE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#5E5CE6"))

                Text("Since you are taking supplements like creatine, it is advisable that you drink more water throughout the day to stay hydrated and support recovery.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#636366"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(Color(hex: "#F3F0FF"))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var reminderSubtitle: String {
        guard let reminder = viewModel.reminder, reminder.isEnabled else {
            return "You will be notified"
        }
        if reminder.reminderTimes.isEmpty {
            return "Add times below"
        }
        let count = reminder.reminderTimes.count
        return count == 1 ? "1 reminder daily" : "\(count) reminders daily"
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Progress ring

private struct WaterProgressRing: View {
    var progress: Double
    var diameter: CGFloat = 208
    var lineWidth: CGFloat = 14
    var fill: Color

    private var track: Color { Color(hex: "#E5E5EA") }

    var body: some View {
        let p = CGFloat(min(max(progress, 0), 1))
        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)
            Circle()
                .trim(from: 0, to: p)
                .stroke(fill, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.35), value: p)
        }
    }
}

// MARK: - Water Goal Edit Sheet

private struct WaterGoalEditSheet: View {
    let goal: Int
    let glassSize: Int
    let onSave: (Int, Int) -> Void
    let onCancel: () -> Void

    @State private var editedGoal: Int
    @State private var editedGlassSize: Int
    @Environment(\.dismiss) private var dismiss

    init(goal: Int, glassSize: Int, onSave: @escaping (Int, Int) -> Void, onCancel: @escaping () -> Void) {
        self.goal = goal
        self.glassSize = glassSize
        self.onSave = onSave
        self.onCancel = onCancel
        _editedGoal = State(initialValue: goal)
        _editedGlassSize = State(initialValue: glassSize)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $editedGoal, in: 1...30) {
                        HStack {
                            Text("Daily goal (glasses)")
                            Spacer()
                            Text("\(editedGoal)")
                                .foregroundColor(Color(hex: "#8E8E93"))
                        }
                    }
                } header: {
                    Text("Goal")
                } footer: {
                    Text("Number of glasses to drink per day.")
                }

                Section {
                    Picker("Glass size", selection: $editedGlassSize) {
                        Text("200 ml").tag(200)
                        Text("250 ml").tag(250)
                        Text("300 ml").tag(300)
                        Text("350 ml").tag(350)
                        Text("400 ml").tag(400)
                    }
                } header: {
                    Text("Glass size")
                } footer: {
                    Text("Volume per glass.")
                }
            }
            .navigationTitle("Water Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editedGoal, editedGlassSize)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Water Reminder Sheet

private struct WaterReminderSheet: View {
    let reminder: WaterReminder?
    let onSave: (Bool, [Date]) -> Void
    let onCancel: () -> Void

    @State private var isEnabled: Bool
    @State private var reminderTimes: [Date]
    @Environment(\.dismiss) private var dismiss

    private static func defaultTimes() -> [Date] {
        let cal = Calendar.current
        return [
            cal.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!,
            cal.date(bySettingHour: 13, minute: 0, second: 0, of: Date())!,
            cal.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        ]
    }

    init(reminder: WaterReminder?, onSave: @escaping (Bool, [Date]) -> Void, onCancel: @escaping () -> Void) {
        self.reminder = reminder
        self.onSave = onSave
        self.onCancel = onCancel
        _isEnabled = State(initialValue: reminder?.isEnabled ?? false)
        _reminderTimes = State(initialValue: (reminder?.reminderTimes.isEmpty == false) ? reminder!.reminderTimes : Self.defaultTimes())
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Reminders", isOn: $isEnabled)
                } footer: {
                    Text("You'll get a notification at each time to drink water.")
                }

                if isEnabled {
                    Section {
                        ForEach(Array(reminderTimes.enumerated()), id: \.offset) { index, time in
                            DatePicker(
                                "Reminder \(index + 1)",
                                selection: Binding(
                                    get: { reminderTimes[index] },
                                    set: { reminderTimes[index] = $0 }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                        }
                        .onDelete(perform: deleteTimes)

                        Button(action: addTime) {
                            Label("Add reminder time", systemImage: "plus.circle.fill")
                                .foregroundColor(Color(hex: "#007AFF"))
                        }
                    } header: {
                        Text("Times")
                    }
                }
            }
            .navigationTitle("Water Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let times = isEnabled ? reminderTimes : []
                        onSave(isEnabled, times)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func addTime() {
        let cal = Calendar.current
        let next = cal.date(byAdding: .hour, value: 1, to: reminderTimes.last ?? Date()) ?? Date()
        reminderTimes.append(cal.date(bySettingHour: cal.component(.hour, from: next), minute: 0, second: 0, of: Date()) ?? next)
    }

    private func deleteTimes(at offsets: IndexSet) {
        reminderTimes.remove(atOffsets: offsets)
    }
}

#Preview {
    WaterTrackingView(userId: "test-user")
}
