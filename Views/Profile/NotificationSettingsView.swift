import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = NotificationSettingsViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section {
                        Toggle("Push Notifications", isOn: $viewModel.pushNotifications)
                            .onChange(of: viewModel.pushNotifications) { _, enabled in
                                Task { await viewModel.saveSettings() }
                                if enabled {
                                    Task { await viewModel.requestPushPermission() }
                                }
                            }
                    } footer: {
                        Text("Push requires notification permission. In-app notifications always appear in your inbox.")
                    }

                    Section {
                        Toggle("Workout Reminders", isOn: $viewModel.workoutReminders)
                            .onChange(of: viewModel.workoutReminders) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }

                        if viewModel.workoutReminders {
                            DatePicker(
                                "Daily reminder time",
                                selection: $viewModel.workoutReminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: viewModel.workoutReminderTime) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }
                        }

                        Toggle("Streak Reminders", isOn: $viewModel.streakReminders)
                            .onChange(of: viewModel.streakReminders) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }

                        Toggle("Plan Updates", isOn: $viewModel.planUpdates)
                            .onChange(of: viewModel.planUpdates) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }

                        Toggle("Achievement Notifications", isOn: $viewModel.achievementNotifications)
                            .onChange(of: viewModel.achievementNotifications) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }
                    } header: {
                        Text("Workouts & Progress")
                    }

                    Section {
                        Toggle("Water Reminders", isOn: $viewModel.waterReminders)
                            .onChange(of: viewModel.waterReminders) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }

                        Toggle("Steps Reminders", isOn: $viewModel.stepsReminders)
                            .onChange(of: viewModel.stepsReminders) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }
                    } header: {
                        Text("Daily Tracking")
                    }

                    Section {
                        Toggle("Product Updates", isOn: $viewModel.marketingNotifications)
                            .onChange(of: viewModel.marketingNotifications) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }

                        Toggle("Email Notifications", isOn: $viewModel.emailNotifications)
                            .onChange(of: viewModel.emailNotifications) { _, _ in
                                Task { await viewModel.saveSettings() }
                            }
                    } header: {
                        Text("Other")
                    }

                    Section {
                        Stepper(
                            "Quiet hours start: \(viewModel.quietHoursStartHour):00",
                            value: $viewModel.quietHoursStartHour,
                            in: 0...23
                        )
                        .onChange(of: viewModel.quietHoursStartHour) { _, _ in
                            Task { await viewModel.saveSettings() }
                        }

                        Stepper(
                            "Quiet hours end: \(viewModel.quietHoursEndHour):00",
                            value: $viewModel.quietHoursEndHour,
                            in: 0...23
                        )
                        .onChange(of: viewModel.quietHoursEndHour) { _, _ in
                            Task { await viewModel.saveSettings() }
                        }
                    } header: {
                        Text("Quiet Hours")
                    } footer: {
                        Text("Local reminders won't fire during quiet hours.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await viewModel.loadSettings()
            }
        }
    }
}

@MainActor
class NotificationSettingsViewModel: ObservableObject {
    @Published var workoutReminders = true
    @Published var planUpdates = true
    @Published var achievementNotifications = true
    @Published var waterReminders = true
    @Published var stepsReminders = true
    @Published var streakReminders = true
    @Published var marketingNotifications = false
    @Published var emailNotifications = false
    @Published var pushNotifications = true
    @Published var workoutReminderTime = Date()
    @Published var quietHoursStartHour = 22
    @Published var quietHoursEndHour = 7

    private let prefsService = NotificationPreferencesService.shared
    private let authService = AuthService.shared

    func loadSettings() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        let prefs = await prefsService.load(for: userId)
        workoutReminders = prefs.workoutReminders
        planUpdates = prefs.planUpdates
        achievementNotifications = prefs.achievementNotifications
        waterReminders = prefs.waterReminders
        stepsReminders = prefs.stepsReminders
        streakReminders = prefs.streakReminders
        marketingNotifications = prefs.marketingNotifications
        emailNotifications = prefs.emailNotifications
        pushNotifications = prefs.pushNotifications
        workoutReminderTime = prefs.workoutReminderTime
        quietHoursStartHour = prefs.quietHoursStartHour
        quietHoursEndHour = prefs.quietHoursEndHour
    }

    func saveSettings() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }

        var prefs = NotificationPreferences()
        prefs.workoutReminders = workoutReminders
        prefs.planUpdates = planUpdates
        prefs.achievementNotifications = achievementNotifications
        prefs.waterReminders = waterReminders
        prefs.stepsReminders = stepsReminders
        prefs.streakReminders = streakReminders
        prefs.marketingNotifications = marketingNotifications
        prefs.emailNotifications = emailNotifications
        prefs.pushNotifications = pushNotifications
        prefs.setWorkoutReminderTime(workoutReminderTime)
        prefs.quietHoursStartHour = quietHoursStartHour
        prefs.quietHoursEndHour = quietHoursEndHour

        await prefsService.save(prefs, userId: userId)

        let userName = authService.getCurrentAuthUser()?.displayName ?? "there"
        await FitnessLocalNotificationService.reschedule(from: prefs, userName: userName)

        if pushNotifications {
            await PushNotificationService.shared.registerIfNeeded(userId: userId)
        }
    }

    func requestPushPermission() async {
        _ = await FitnessLocalNotificationService.requestAuthorizationIfNeeded()
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        await PushNotificationService.shared.registerIfNeeded(userId: userId)
    }
}

#Preview {
    NotificationSettingsView()
}
