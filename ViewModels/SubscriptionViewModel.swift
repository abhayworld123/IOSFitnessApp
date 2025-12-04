import Foundation
import SwiftUI
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var selectedProduct: Product?
    @Published var isPremium: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var purchaseInProgress = false
    
    private let subscriptionService = SubscriptionService.shared
    private let authService = AuthService.shared
    
    init() {
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // MARK: - Fetch Products
    
    func fetchProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await subscriptionService.fetchProducts()
            // Select annual by default (usually the second product)
            if products.count > 1 {
                selectedProduct = products[1] // Annual subscription
            } else if !products.isEmpty {
                selectedProduct = products[0] // Monthly subscription
            }
        } catch {
            errorMessage = "Failed to load subscription options. Please try again."
            print("Error fetching products: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Product
    
    func purchase(_ product: Product) async {
        guard let userId = authService.getCurrentAuthUser()?.uid else {
            errorMessage = "Please sign in to purchase a subscription"
            return
        }
        
        purchaseInProgress = true
        errorMessage = nil
        
        do {
            _ = try await subscriptionService.purchase(product)
            
            // Refresh subscription status
            await checkSubscriptionStatus()
            
            // Refresh user data
            if let user = try? await authService.fetchCurrentUserData() {
                // User data will be updated via AuthService's published property
            }
            
            HapticFeedback.success()
        } catch {
            if let subscriptionError = error as? SubscriptionError {
                switch subscriptionError {
                case .userCancelled:
                    // User cancelled, don't show error
                    break
                case .pending:
                    errorMessage = "Purchase is pending approval"
                default:
                    errorMessage = subscriptionError.errorDescription ?? "Purchase failed. Please try again."
                }
            } else {
                errorMessage = "Purchase failed. Please try again."
            }
            HapticFeedback.error()
            print("Error purchasing product: \(error.localizedDescription)")
        }
        
        purchaseInProgress = false
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await subscriptionService.restorePurchases()
            await checkSubscriptionStatus()
            
            // Refresh user data
            if let user = try? await authService.fetchCurrentUserData() {
                // User data will be updated via AuthService's published property
            }
            
            errorMessage = nil
            HapticFeedback.success()
        } catch {
            errorMessage = "Failed to restore purchases. Please try again."
            HapticFeedback.error()
            print("Error restoring purchases: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Check Subscription Status
    
    func checkSubscriptionStatus() async {
        let status = await subscriptionService.checkSubscriptionStatus()
        isPremium = status == .premium
    }
    
    // MARK: - Select Product
    
    func selectProduct(_ product: Product) {
        selectedProduct = product
        HapticFeedback.impact(style: .light)
    }
}

