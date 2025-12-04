import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Listen for auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    do {
                        try await self?.fetchUserData(userId: user.uid)
                    } catch {
                        // Silently handle errors during auth state changes
                        // User data will be fetched when explicitly needed
                        print("Failed to fetch user data: \(error.localizedDescription)")
                    }
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
        do {
            try Auth.auth().signOut()
            currentUser = nil
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
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard let data = document.data() else {
            throw AuthError.userNotFound
        }
        
        let user = try Firestore.Decoder().decode(User.self, from: data)
        currentUser = user
        return user
    }
    
    // MARK: - Save User Data
    private func saveUserData(_ user: User) async throws {
        let data = try Firestore.Encoder().encode(user)
        try await db.collection("users").document(user.id).setData(data)
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
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
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

