import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppConstants.Colors.primary,
                    AppConstants.Colors.secondary
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppConstants.Design.spacing) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Back Button
                    HStack {
                        NavigationLink(destination: LoginView()
                            .environmentObject(authViewModel)) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // App Logo/Title
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10)
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Start your fitness journey today")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 30)
                    
                    // Sign Up Card
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            TextField("Enter your name", text: $name)
                                .textContentType(.name)
                                .autocapitalization(.words)
                                .focused($focusedField, equals: .name)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .name ? AppConstants.Colors.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .email ? AppConstants.Colors.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            SecureField("Enter your password", text: $password)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .password)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .password ? AppConstants.Colors.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            
                            if !password.isEmpty && !password.isValidPassword {
                                Text("Password must be at least 6 characters")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppConstants.Colors.error)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.Colors.textPrimary)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            focusedField == .confirmPassword ? AppConstants.Colors.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppConstants.Colors.error)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = authViewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppConstants.Colors.error)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppConstants.Colors.error)
                                Spacer()
                            }
                            .padding()
                            .background(AppConstants.Colors.error.opacity(0.1))
                            .cornerRadius(12)
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        // Sign Up Button
                        Button(action: {
                            Task {
                                await authViewModel.signUp(
                                    email: email,
                                    password: password,
                                    confirmPassword: confirmPassword,
                                    name: name
                                )
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppConstants.Colors.primary,
                                        AppConstants.Colors.secondary
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(AppConstants.Design.cornerRadius)
                            .shadow(color: AppConstants.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(authViewModel.isLoading || !isFormValid)
                        .opacity((authViewModel.isLoading || !isFormValid) ? 0.6 : 1.0)
                        .scaleEffect(authViewModel.isLoading ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: AppConstants.Design.animationDuration), value: authViewModel.isLoading)
                        
                        // Sign In Link
                        HStack {
                            Text("Already have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            
                            NavigationLink(destination: LoginView()
                                .environmentObject(authViewModel)) {
                                Text("Sign In")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppConstants.Colors.primary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(AppConstants.Design.cardPadding)
                    .cardStyle()
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            authViewModel.clearError()
        }
    }
    
    private var isFormValid: Bool {
        name.isValidName &&
        email.isValidEmail &&
        password.isValidPassword &&
        confirmPassword == password &&
        !confirmPassword.isEmpty
    }
}

#Preview {
    NavigationView {
        SignUpView()
    }
}

