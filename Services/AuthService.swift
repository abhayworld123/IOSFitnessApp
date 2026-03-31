import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Listen for auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let user = user else {
                    self?.currentUser = nil
                    return
                }
                do {
                    _ = try await self?.fetchUserData(userId: user.uid)
                } catch {
                    // Fallback: don't leave stale user; clear and let ViewModel retry or show login
                    self?.currentUser = nil
                    print("AuthService: Failed to fetch user data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @Published var currentUser: User?
    
    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = try await fetchUserData(userId: authResult.user.uid)
            return user
        } catch {
            throw AuthError.from(error)
        }
    }
    
    // MARK: - Sign In with Google
    func signInWithGoogle() async throws -> User {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            throw AuthError.unknown(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"]))
        }
        // Use topmost presented VC so Google sheet has a valid presenter (more reliable on device)
        var presenting = rootViewController
        while let presented = presenting.presentedViewController {
            presenting = presented
        }
        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        } catch {
            let nsError = error as NSError
            if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
                throw AuthError.cancelled
            }
            throw AuthError.from(error)
        }
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.unknown(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token from Google"]))
        }
        // GIDToken is non-optional in Google Sign-In SDK
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        let email = result.user.profile?.email ?? ""
        let name = result.user.profile?.name ?? "Google User"
        return try await getOrCreateUserData(
            userId: authResult.user.uid,
            email: email,
            name: name
        )
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String) async throws -> User {
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user document in Firestore
            let newUser = User(
                id: authResult.user.uid,
                email: email,
                name: name,
                subscriptionStatus: .free
            )
            
            try await saveUserData(newUser)
            currentUser = newUser
            return newUser
        } catch {
            throw AuthError.from(error)
        }
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        currentUser = nil
        GIDSignIn.sharedInstance.signOut()
        do {
            try Auth.auth().signOut()
        } catch {
            throw AuthError.signOutFailed
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AuthError.from(error)
        }
    }
    
    // MARK: - Fetch User Data
    private func fetchUserData(userId: String) async throws -> User {
        let document = try await db.collection(FirestoreCollections.users).document(userId).getDocument()
        
        guard let data = document.data() else {
            currentUser = nil
            throw AuthError.userNotFound
        }
        
        do {
            let user = try Firestore.Decoder().decode(User.self, from: data)
            currentUser = user
            return user
        } catch {
            currentUser = nil
            throw AuthError.userNotFound
        }
    }

    /// Get existing user or create Firestore document for new users (e.g. Google/Phone).
    private func getOrCreateUserData(userId: String, email: String, name: String) async throws -> User {
        let document = try await db.collection(FirestoreCollections.users).document(userId).getDocument()
        if let data = document.data(),
           let user = try? Firestore.Decoder().decode(User.self, from: data) {
            currentUser = user
            return user
        }
        let newUser = User(
            id: userId,
            email: email.isEmpty ? "\(userId)@auth.local" : email,
            name: name,
            subscriptionStatus: .free
        )
        try await saveUserData(newUser)
        currentUser = newUser
        return newUser
    }
    
    // MARK: - Save User Data
    private func saveUserData(_ user: User) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db.collection(FirestoreCollections.users).document(user.id).setData(data)
    }
    
    // MARK: - Get Current Auth User
    func getCurrentAuthUser() -> FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Fetch Current User Data
    func fetchCurrentUserData() async throws -> User? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        return try await fetchUserData(userId: userId)
    }

    // MARK: - Onboarding profile (merge into Firestore while user completes steps)
    func mergeOnboardingDetails(_ details: BasicDetailsData) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        var data: [String: Any] = [
            FirestoreFields.updatedAt: Timestamp(date: Date())
        ]

        if let gender = details.gender {
            data[FirestoreFields.gender] = gender.rawValue
        }
        if let age = details.age {
            data[FirestoreFields.age] = age
        }
        if let w = details.weight {
            let kg = details.weightUnit == .kg ? w : details.weightUnit.convert(w, to: .kg)
            data[FirestoreFields.weight] = kg
        }
        if let heightCm = details.height {
            data[FirestoreFields.height] = heightCm
        }
        if let goal = details.fitnessGoal {
            data[FirestoreFields.fitnessGoal] = goal.rawValue
        }
        if let level = details.activityLevel {
            data[FirestoreFields.activityLevel] = level.rawValue
        }
        if !details.physicalLimitations.isEmpty {
            data[FirestoreFields.physicalLimitations] = details.physicalLimitations
        }
        if !details.interestedActivities.isEmpty {
            data[FirestoreFields.interestedActivities] = details.interestedActivities
        }
        if let meal = details.mealPreference {
            data[FirestoreFields.mealPreference] = meal.rawValue
        }
        data[FirestoreFields.heightUnitPreference] = details.heightUnit.rawValue
        data[FirestoreFields.weightUnitPreference] = details.weightUnit.rawValue

        try await db.collection(FirestoreCollections.users).document(uid).setData(data, merge: true)
        _ = try await fetchUserData(userId: uid)
    }

    // MARK: - Phone Auth
    /// Sends SMS verification to the phone number. Returns verification ID to use in signInWithPhone.
    func verifyPhoneNumber(_ phoneNumber: String) async throws -> String {
        #if !targetEnvironment(simulator)
        // Register for remote notifications only when phone auth is initiated.
        // This avoids startup-time crashes related to APNs credential updates.
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif

        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "+" else {
            throw AuthError.unknown(NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Phone number must include country code (E.164), e.g. +1XXXXXXXXXX"]))
        }

        let rootViewController: UIViewController? = await MainActor.run {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let keyWindow = windowScenes
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
            let root = keyWindow?.rootViewController
            var top = root
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }
        guard let rootViewController else {
            throw AuthError.unknown(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"]))
        }

        let uidependency = FirebaseAuthUIDelegate(viewController: rootViewController)
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(trimmed, uiDelegate: uidependency) { verificationID, error in
                if let error = error {
                    let authError = error as NSError
                    if authError.domain == AuthErrorDomain,
                       authError.code == AuthErrorCode.invalidPhoneNumber.rawValue {
                        continuation.resume(throwing: AuthError.invalidPhoneNumber)
                    } else {
                        continuation.resume(throwing: AuthError.from(error))
                    }
                    return
                }
                guard let verificationID = verificationID else {
                    continuation.resume(throwing: AuthError.unknown(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No verification ID"])))
                    return
                }
                continuation.resume(returning: verificationID)
            }
        }
    }

    /// Signs in with the verification ID and code from SMS. Creates Firestore user if new.
    func signInWithPhone(verificationID: String, verificationCode: String, name: String?) async throws -> User {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        let authResult: AuthDataResult
        do {
            authResult = try await Auth.auth().signIn(with: credential)
        } catch {
            let nsError = error as NSError
            if nsError.domain == AuthErrorDomain, nsError.code == AuthErrorCode.invalidVerificationCode.rawValue {
                throw AuthError.invalidVerificationCode
            }
            throw AuthError.from(error)
        }
        let displayName = name?.isEmpty == false ? name! : "Phone User"
        return try await getOrCreateUserData(
            userId: authResult.user.uid,
            email: "",
            name: displayName
        )
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case signOutFailed
    case cancelled
    case invalidVerificationCode
    case invalidPhoneNumber
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Sign in was cancelled."
        case .invalidVerificationCode:
            return "Invalid verification code. Please try again."
        case .invalidPhoneNumber:
            return "Invalid phone number. Please check and try again."
        case .invalidEmail:
            return "Invalid email address"
        case .invalidPassword:
            return "Invalid password. Password must be at least 6 characters."
        case .userNotFound:
            return "User not found. Please check your email and password."
        case .emailAlreadyInUse:
            return "This email is already registered. Please sign in instead."
        case .weakPassword:
            return "Password is too weak. Please use at least 6 characters."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .signOutFailed:
            return "Failed to sign out. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    static func from(_ error: Error) -> AuthError {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.invalidEmail.rawValue:
                return .invalidEmail
            case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.userNotFound.rawValue:
                return .userNotFound
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return .emailAlreadyInUse
            case AuthErrorCode.weakPassword.rawValue:
                return .weakPassword
            case AuthErrorCode.networkError.rawValue:
                return .networkError
            default:
                return .unknown(error)
            }
        }
        return .unknown(error)
    }
}

