import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero Section
                        heroSection
                        
                        // Benefits Section
                        benefitsSection
                        
                        // Subscription Options
                        subscriptionOptionsSection
                        
                        // Purchase Button
                        purchaseButton
                        
                        // Restore Purchases
                        restorePurchasesButton
                        
                        // Terms and Privacy
                        termsAndPrivacySection
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Upgrade to Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                }
            }
            .task {
                await viewModel.fetchProducts()
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Unlock Premium")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
            
            Text("Get unlimited access to all workouts and features")
                .font(.system(size: 18))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Benefits Section
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Premium Benefits")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                BenefitRow(
                    icon: "play.circle.fill",
                    title: "Unlimited Video Access",
                    description: "Access all premium workout videos"
                )
                
                BenefitRow(
                    icon: "calendar",
                    title: "Personalized Workout Plans",
                    description: "Get custom plans tailored to your goals"
                )
                
                BenefitRow(
                    icon: "arrow.down.circle.fill",
                    title: "Offline Downloads",
                    description: "Download workouts for offline viewing (coming soon)"
                )
                
                BenefitRow(
                    icon: "xmark.circle.fill",
                    title: "No Ads",
                    description: "Enjoy an ad-free experience"
                )
                
                BenefitRow(
                    icon: "headphones",
                    title: "Priority Support",
                    description: "Get help when you need it"
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Subscription Options Section
    
    private var subscriptionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Plan")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                .padding(.horizontal, 20)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.products.isEmpty {
                Text("Subscription options are currently unavailable. Please try again later.")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                SubscriptionOptionsView(viewModel: viewModel) { product in
                    // Product selected, ready to purchase
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    if let product = viewModel.selectedProduct {
                        await viewModel.purchase(product)
                        
                        // Check if purchase was successful
                        if viewModel.isPremium {
                            dismiss()
                        }
                    }
                }
            }) {
                HStack {
                    if viewModel.purchaseInProgress {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Start Free Trial")
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
            .disabled(viewModel.selectedProduct == nil || viewModel.purchaseInProgress || viewModel.isLoading)
            .opacity((viewModel.selectedProduct == nil || viewModel.purchaseInProgress || viewModel.isLoading) ? 0.6 : 1.0)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.error)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Restore Purchases Button
    
    private var restorePurchasesButton: some View {
        Button(action: {
            Task {
                await viewModel.restorePurchases()
                if viewModel.isPremium {
                    dismiss()
                }
            }
        }) {
            Text("Restore Purchases")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppConstants.Colors.primary)
        }
        .disabled(viewModel.isLoading)
    }
    
    // MARK: - Terms and Privacy Section
    
    private var termsAndPrivacySection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Button("Terms of Service") {
                    // Open terms URL
                }
                .font(.system(size: 12))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                
                Text("•")
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                
                Button("Privacy Policy") {
                    // Open privacy URL
                }
                .font(.system(size: 12))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            
            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
            }
            
            Spacer()
        }
        .padding()
        .background(AppConstants.Colors.cardBackground(colorScheme: colorScheme))
        .cornerRadius(AppConstants.Design.cornerRadius)
    }
}

#Preview {
    PaywallView()
        .environmentObject(AuthViewModel())
}

