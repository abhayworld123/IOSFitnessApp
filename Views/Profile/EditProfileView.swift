import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Name", text: $name)
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                        
                        TextField("Email", text: $email)
                            .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    } header: {
                        Text("Profile Information")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isLoading || name.isEmpty || email.isEmpty)
                }
            }
            .onAppear {
                name = authViewModel.currentUser?.name ?? ""
                email = authViewModel.currentUser?.email ?? ""
            }
        }
    }
    
    private func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await viewModel.updateProfile(name: name, email: email)
            await authViewModel.checkAuthenticationStatus()
            dismiss()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error()
        }
        
        isLoading = false
    }
}
