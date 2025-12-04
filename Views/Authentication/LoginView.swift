import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var forgotPasswordEmail = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
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
                        .frame(height: 60)
                    
                    // App Logo/Title
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 10)
                        
                        Text("Fitness App")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Transform your body, transform your life")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 40)
                    
                    // Login Card
                    VStack(spacing: 24) {
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
                                .textContentType(.password)
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
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button(action: {
                                showForgotPassword = true
                            }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppConstants.Colors.primary)
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
                        
                        // Sign In Button
                        Button(action: {
                            Task {
                                await authViewModel.signIn(email: email, password: password)
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
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
                        .disabled(authViewModel.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((authViewModel.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .scaleEffect(authViewModel.isLoading ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: AppConstants.Design.animationDuration), value: authViewModel.isLoading)
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.Colors.textSecondary)
                            
                            NavigationLink(destination: SignUpView()
                                .environmentObject(authViewModel)) {
                                Text("Sign Up")
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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(email: $forgotPasswordEmail, viewModel: authViewModel)
        }
        .onAppear {
            authViewModel.clearError()
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Binding var email: String
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(AppConstants.Colors.primary)
                        .padding(.top, 40)
                    
                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
                        .cornerRadius(12)
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.Colors.error)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppConstants.Colors.error.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppConstants.Colors.success)
                            Text("Reset email sent! Check your inbox.")
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.Colors.success)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppConstants.Colors.success.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.resetPassword(email: email)
                            if viewModel.errorMessage == nil {
                                showSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    dismiss()
                                }
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Reset Link")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppConstants.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.Design.cornerRadius)
                    }
                    .disabled(viewModel.isLoading || email.isEmpty)
                    .opacity((viewModel.isLoading || email.isEmpty) ? 0.6 : 1.0)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        LoginView()
    }
}

