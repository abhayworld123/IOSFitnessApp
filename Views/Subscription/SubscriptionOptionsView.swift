import SwiftUI
import StoreKit

struct SubscriptionOptionsView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    let onSelect: (Product) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.products, id: \.id) { product in
                SubscriptionOptionCard(
                    product: product,
                    isSelected: viewModel.selectedProduct?.id == product.id,
                    isBestValue: isAnnualProduct(product)
                ) {
                    viewModel.selectProduct(product)
                    onSelect(product)
                }
            }
        }
    }
    
    private func isAnnualProduct(_ product: Product) -> Bool {
        return product.id.contains("annual")
    }
}

// MARK: - Subscription Option Card

struct SubscriptionOptionCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(product.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                            
                            if isBestValue {
                                Text("BEST VALUE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.yellow)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(product.displayPrice)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white.opacity(0.9) : AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        
                        if let subscription = product.subscription {
                            if let period = subscription.subscriptionPeriod.unit.localizedDescription {
                                Text(period)
                                    .font(.system(size: 14))
                                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.white : AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.5), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .padding()
            .background(
                isSelected ?
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppConstants.Colors.primary,
                        AppConstants.Colors.secondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppConstants.Colors.cardBackground(colorScheme: colorScheme),
                        AppConstants.Colors.cardBackground(colorScheme: colorScheme)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppConstants.Design.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadius)
                    .stroke(isSelected ? Color.clear : AppConstants.Colors.textSecondary(colorScheme: colorScheme).opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Product Extensions

extension Product {
    var displayName: String {
        if id.contains("annual") {
            return "Annual"
        } else if id.contains("monthly") {
            return "Monthly"
        }
        return "Subscription"
    }
}

extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String? {
        switch self {
        case .day:
            return "per day"
        case .week:
            return "per week"
        case .month:
            return "per month"
        case .year:
            return "per year"
        @unknown default:
            return nil
        }
    }
}

#Preview {
    SubscriptionOptionsView(
        viewModel: SubscriptionViewModel(),
        onSelect: { _ in }
    )
    .padding()
    .background(AppConstants.Colors.background(colorScheme: .dark))
}

