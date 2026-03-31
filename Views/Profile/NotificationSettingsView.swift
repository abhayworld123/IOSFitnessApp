import SwiftUI
import FirebaseFirestore

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = NotificationSettingsViewModel()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        Toggle("Workout Reminders", isOn: $viewModel.workoutReminders)
                            .onChange(of: viewModel.workoutReminders) { _ in
                                Task {
                                    await viewModel.saveSettings()
                                }
                            }
                        
                        Toggle("Plan Updates", isOn: $viewModel.planUpdates)
                            .onChange(of: viewModel.planUpdates) { _ in
                                Task {
                                    await viewModel.saveSettings()
                                }
                            }
                        
                        Toggle("Achievement Notifications", isOn: $viewModel.achievementNotifications)
                            .onChange(of: viewModel.achievementNotifications) { _ in
                                Task {
                                    await viewModel.saveSettings()
                                }
                            }
                    } header: {
                        Text("Notification Preferences")
                    } footer: {
                        Text("Manage which notifications you'd like to receive from the app.")
                    }
                    
                    Section {
                        Toggle("Email Notifications", isOn: $viewModel.emailNotifications)
                            .onChange(of: viewModel.emailNotifications) { _ in
                                Task {
                                    await viewModel.saveSettings()
                                }
                            }
                    } header: {
                        Text("Email")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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
    @Published var emailNotifications = false
    
    private let db = Firestore.firestore()
    private let authService = AuthService.shared
    
    func loadSettings() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        
        do {
            let doc = try await db.collection(FirestoreCollections.users)
                .document(userId)
                .collection("settings")
                .document("notifications")
                .getDocument()
            
            if let data = doc.data() {
                workoutReminders = data["workoutReminders"] as? Bool ?? true
                planUpdates = data["planUpdates"] as? Bool ?? true
                achievementNotifications = data["achievementNotifications"] as? Bool ?? true
                emailNotifications = data["emailNotifications"] as? Bool ?? false
            }
        } catch {
            print("Failed to load notification settings: \(error)")
        }
    }
    
    func saveSettings() async {
        guard let userId = authService.getCurrentAuthUser()?.uid else { return }
        
        let settings: [String: Any] = [
            "workoutReminders": workoutReminders,
            "planUpdates": planUpdates,
            "achievementNotifications": achievementNotifications,
            "emailNotifications": emailNotifications,
            "updatedAt": Timestamp(date: Date())
        ]
        
        do {
            try await db.collection(FirestoreCollections.users)
                .document(userId)
                .collection("settings")
                .document("notifications")
                .setData(settings, merge: true)
        } catch {
            print("Failed to save notification settings: \(error)")
        }
    }
}

#Preview {
    NotificationSettingsView()
}


