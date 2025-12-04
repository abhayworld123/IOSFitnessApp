import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let authService = AuthService.shared
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        isAuthenticated = authService.isAuthenticated
        currentUser = authService.currentUser
        
        // If authenticated but no user data, try to fetch it
        if isAuthenticated && currentUser == nil {
            Task {
                do {
                    if let user = try await authService.fetchCurrentUserData() {
                        currentUser = user
                        // Sync subscription status
                        await syncSubscriptionStatus()
                    }
                } catch {
                    // If we can't fetch user data, sign out
                    try? authService.signOut()
                    isAuthenticated = false
                }
            }
        } else if isAuthenticated {
            // Sync subscription status if user is already loaded
            Task {
                await syncSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Sync Subscription Status
    
    func syncSubscriptionStatus() async {
        let subscriptionService = SubscriptionService.shared
        let status = await subscriptionService.checkSubscriptionStatus()
        
        // Update user if subscription status changed
        if let currentUser = currentUser,
           currentUser.subscriptionStatus != status {
            // Refresh user data to get updated subscription status
            if let updatedUser = try? await authService.fetchCurrentUserData() {
                self.currentUser = updatedUser
            }
        }
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Validate input
        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            HapticFeedback.error()
            return
        }
        
        guard password.isValidPassword else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            HapticFeedback.error()
            return
        }
        
        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            HapticFeedback.success()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? "Sign in failed. Please try again."
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, confirmPassword: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        // Validate input
        guard name.isValidName else {
            errorMessage = "Please enter a valid name (at least 2 characters)"
            isLoading = false
            HapticFeedback.error()
            return
        }
        
        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            HapticFeedback.error()
            return
        }
        
        guard password.isValidPassword else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            HapticFeedback.error()
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            HapticFeedback.error()
            return
        }
        
        do {
            let user = try await authService.signUp(email: email, password: password, name: name)
            currentUser = user
            isAuthenticated = true
            HapticFeedback.success()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? "Sign up failed. Please try again."
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try authService.signOut()
            isAuthenticated = false
            currentUser = nil
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to sign out. Please try again."
            HapticFeedback.error()
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            HapticFeedback.error()
            return
        }
        
        do {
            try await authService.resetPassword(email: email)
            errorMessage = nil
            HapticFeedback.success()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? "Failed to send reset email. Please try again."
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
}

