import SwiftUI

struct WaterTrackingView: View {
    let userId: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: WaterTrackingViewModel
    @State private var showEditGoal = false
    @State private var showReminderSheet = false
    
    init(userId: String) {
        self.userId = userId
        _viewModel = StateObject(wrappedValue: WaterTrackingViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Navigation Header
                        navigationHeader
                        
                        // Empty state when no water logged today
                        if (viewModel.currentIntake?.glassesConsumed ?? 0) == 0 {
                            waterEmptyState
                        }
                        
                        // Water Goal Card
                        waterGoalCard
                        
                        // Analysis Card
                        analysisCard
                        
                        // Set Reminder Card
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
            if viewModel.needsGoalSetup {
                showEditGoal = true
            }
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
        .onChange(of: viewModel.needsGoalSetup) { _, need in
            if need && !viewModel.isLoading {
                showEditGoal = true
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

    // MARK: - Empty State

    private var waterEmptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#007AFF").opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "drop.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#007AFF"))
            }
            Text("No water logged yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            Text("Tap the + button below to log your first glass and start your daily goal.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "#8E8E93"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Navigation Header
    
    private var navigationHeader: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Water")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            Spacer()
            
            // Date selector
            Button(action: {
                // TODO: Show date picker
            }) {
                HStack(spacing: 4) {
                    Text("Today")
                        .font(.system(size: 16, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Water Goal Card
    
    private var waterGoalCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with Goal and Edit
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.goal <= 0 ? "Set your daily water goal" : "Goal: \(viewModel.goal) Glasses")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    
                    Text("1 Glass: \(viewModel.glassSize) ml")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
                
                Spacer()
                
                Button(action: {
                    showEditGoal = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#F5F5F7"))
                        .clipShape(Circle())
                }
            }
            
            // Water Glass Icon
            HStack {
                Spacer()
                WaterGlassIcon(
                    progress: viewModel.currentIntake?.progress ?? 0.0,
                    size: 114
                )
                Spacer()
            }
            
            // Counter
            glassCounter
            
            // Progress Message
            let message = viewModel.progressMessage
            VStack(spacing: 4) {
                Text(message.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                Text(message.subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Glass Counter
    
    private var glassCounter: some View {
        HStack(spacing: 16) {
            // Minus button
            Button(action: {
                viewModel.decrementGlass()
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#E5E5EA"))
                    .clipShape(Circle())
            }
            
            // Current glasses
            Text("\(viewModel.currentIntake?.glassesConsumed ?? 0)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
                .frame(minWidth: 48, alignment: .center)
            
            // Plus button
            Button(action: {
                viewModel.incrementGlass()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: "#E5E5EA"))
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Analysis Card
    
    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            Text("Last 7 days")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "#8E8E93"))
            
            // Bar Chart
            waterBarChart
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Water Bar Chart
    
    private var waterBarChart: some View {
        VStack(spacing: 12) {
            // Bars
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { index in
                    VStack(spacing: 8) {
                        let glasses = viewModel.getIntakeForDay(index)
                        let maxGlasses = max(viewModel.goal, viewModel.weeklyData.map { $0.glassesConsumed }.max() ?? 12)
                        let barHeight = maxGlasses > 0 ? CGFloat(glasses) / CGFloat(maxGlasses) * 100 : 0
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(glasses > 0 ? Color(hex: "#FF9500") : Color(hex: "#E5E5EA"))
                            .frame(width: 32, height: max(barHeight, 4))
                        
                        // Day label
                        Text(dayLabel(for: index))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#8E8E93"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
    }
    
    private func dayLabel(for index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
    
    // MARK: - Reminder Card
    
    private var reminderCard: some View {
        VStack(spacing: 12) {
            Button(action: { showReminderSheet = true }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: viewModel.reminder?.isEnabled == true ? "bell.fill" : "bell.badge")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 4) {
                Text("Set Reminder")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                Text(reminderSubtitle)
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

    private var reminderSubtitle: String {
        guard let reminder = viewModel.reminder, reminder.isEnabled else {
            return "Get notified to drink water"
        }
        if reminder.reminderTimes.isEmpty {
            return "Add times below"
        }
        let count = reminder.reminderTimes.count
        return count == 1 ? "1 reminder daily" : "\(count) reminders daily"
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
