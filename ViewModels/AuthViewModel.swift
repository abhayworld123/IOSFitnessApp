import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var phoneVerificationID: String?

    private let authService = AuthService.shared
    
    /// Show profile onboarding only for signed-in users who have not completed it (Firestore or legacy filled profile).
    var needsProfileOnboarding: Bool {
        guard isAuthenticated, let user = currentUser else { return false }
        return !user.hasCompletedProfileOnboarding
    }
    
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
                        await syncSubscriptionStatus()
                    } else {
                        currentUser = nil
                        isAuthenticated = false
                    }
                } catch {
                    currentUser = nil
                    isAuthenticated = false
                    try? authService.signOut()
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
            errorMessage = password.passwordValidationError ?? "Please enter a valid password"
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
            errorMessage = password.passwordValidationError ?? "Please enter a valid password"
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

    // MARK: - Sign In with Google
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await authService.signInWithGoogle()
            currentUser = user
            isAuthenticated = true
            HapticFeedback.success()
        } catch {
            if case AuthError.cancelled = error { }
            else {
                errorMessage = (error as? AuthError)?.errorDescription ?? "Google sign in failed. Please try again."
                HapticFeedback.error()
            }
        }
        isLoading = false
    }

    // MARK: - Phone Auth
    func requestPhoneVerification(phoneNumber: String) async {
        errorMessage = nil
        do {
            let verificationID = try await authService.verifyPhoneNumber(phoneNumber)
            phoneVerificationID = verificationID
            HapticFeedback.success()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? "Failed to send verification code."
            HapticFeedback.error()
        }
    }

    func signInWithPhone(verificationID: String, verificationCode: String, name: String?) async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await authService.signInWithPhone(
                verificationID: verificationID,
                verificationCode: verificationCode,
                name: name
            )
            currentUser = user
            isAuthenticated = true
            phoneVerificationID = nil
            HapticFeedback.success()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? "Phone sign in failed. Please try again."
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

    // MARK: - Onboarding → Firestore
    /// - Returns: `true` if merge succeeded (or skipped when unauthenticated without marking complete).
    @discardableResult
    func persistOnboardingDetails(
        _ details: BasicDetailsData,
        markProfileOnboardingComplete: Bool = false,
        clearedFields: Set<OnboardingClearedField> = []
    ) async -> Bool {
        guard isAuthenticated else { return false }
        do {
            try await authService.mergeOnboardingDetails(
                details,
                markProfileOnboardingComplete: markProfileOnboardingComplete,
                clearedFields: clearedFields
            )
            currentUser = authService.currentUser
            return true
        } catch {
            print("Onboarding Firestore sync: \(error.localizedDescription)")
            return false
        }
    }

    /// Reload profile from Firestore (e.g. after onboarding or profile edits).
    func refreshCurrentUser() async {
        guard isAuthenticated else { return }
        do {
            if let user = try await authService.fetchCurrentUserData() {
                currentUser = user
            }
        } catch {
            print("Refresh user: \(error.localizedDescription)")
        }
    }
}

