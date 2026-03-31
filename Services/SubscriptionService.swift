import Foundation
import StoreKit
import FirebaseFirestore

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    private let db = Firestore.firestore()
    private let productIds = ["fitness_monthly", "fitness_annual"]
    
    private init() {
        // Start listening for transaction updates
        Task {
            await listenForTransactions()
        }
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async throws -> [Product] {
        let products = try await Product.products(for: productIds)
        return products.sorted { product1, product2 in
            // Sort by price (monthly first, then annual)
            product1.id.contains("monthly") && !product2.id.contains("monthly")
        }
    }
    
    // MARK: - Purchase Product
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Update user subscription status in Firestore
            await updateSubscriptionStatus(for: transaction)
            
            // Finish the transaction
            await transaction.finish()
            
            return transaction
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        
        // Check for current entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                await updateSubscriptionStatus(for: transaction)
            }
        }
    }
    
    // MARK: - Check Subscription Status
    
    func checkSubscriptionStatus() async -> SubscriptionStatus {
        guard let userId = AuthService.shared.getCurrentAuthUser()?.uid else {
            return .free
        }
        
        // Check Firestore first
        do {
            let userDoc = try await db.collection(FirestoreCollections.users).document(userId).getDocument()
            if let data = userDoc.data(),
               let statusString = data[FirestoreFields.subscriptionStatus] as? String,
               let status = SubscriptionStatus(rawValue: statusString) {
                
                // If premium, verify with StoreKit
                if status == .premium {
                    if await verifySubscriptionWithStoreKit() {
                        return .premium
                    } else {
                        // Subscription expired, update Firestore
                        try await db.collection(FirestoreCollections.users).document(userId).updateData([
                            FirestoreFields.subscriptionStatus: SubscriptionStatus.free.rawValue
                        ])
                        return .free
                    }
                }
                
                return status
            }
        } catch {
            print("Error checking subscription status: \(error.localizedDescription)")
        }
        
        // Fallback to StoreKit verification
        if await verifySubscriptionWithStoreKit() {
            // Update Firestore
            if let userId = AuthService.shared.getCurrentAuthUser()?.uid {
                try? await db.collection(FirestoreCollections.users).document(userId).updateData([
                    FirestoreFields.subscriptionStatus: SubscriptionStatus.premium.rawValue
                ])
            }
            return .premium
        }
        
        return .free
    }
    
    // MARK: - Verify Subscription with StoreKit
    
    private func verifySubscriptionWithStoreKit() async -> Bool {
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Check if transaction is for our products
                if productIds.contains(transaction.productID) {
                    // Check if subscription is still valid
                    if transaction.revocationDate == nil {
                        hasActiveSubscription = true
                        break
                    }
                }
            }
        }
        
        return hasActiveSubscription
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await updateSubscriptionStatus(for: transaction)
                await transaction.finish()
            }
        }
    }
    
    // MARK: - Update Subscription Status in Firestore
    
    private func updateSubscriptionStatus(for transaction: StoreKit.Transaction) async {
        guard let userId = AuthService.shared.getCurrentAuthUser()?.uid else {
            return
        }
        
        // Check if subscription is active
        let isActive = transaction.revocationDate == nil
        
        do {
            try await db.collection(FirestoreCollections.users).document(userId).updateData([
                FirestoreFields.subscriptionStatus: isActive ? SubscriptionStatus.premium.rawValue : SubscriptionStatus.free.rawValue,
                "subscriptionExpiryDate": transaction.expirationDate?.timeIntervalSince1970 ?? NSNull(),
                "subscriptionUpdatedAt": Timestamp(date: Date())
            ])
            
            // Refresh user data in AuthService
            if let user = try? await AuthService.shared.fetchCurrentUserData() {
                // User data will be updated via AuthService's published property
            }
        } catch {
            print("Error updating subscription status: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T where T: Sendable {
        switch result {
        case .unverified:
            throw SubscriptionError.unverified
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Subscription Errors

enum SubscriptionError: LocalizedError {
    case userCancelled
    case pending
    case unverified
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .unverified:
            return "Purchase could not be verified"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

