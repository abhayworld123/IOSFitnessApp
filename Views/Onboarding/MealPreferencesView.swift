import SwiftUI

struct MealPreferencesView: View {
    @Binding var basicDetails: BasicDetailsData
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let currentPage: Int
    let totalPages: Int
    
    @State private var selectedPreference: MealPreference?
    
    var body: some View {
        ZStack {
            // White Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: {
                        HapticFeedback.impact(style: .light)
                        onBack()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17))
                        }
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        HapticFeedback.impact(style: .light)
                        onSkip()
                    }) {
                        Text("Skip")
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: "#1C1C1E"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What are your meal preferences?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                            
                            Text("In order to calculate your data properly we need your basic information")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#A8A8A8"))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        
                        // Meal Preference Options
                        VStack(spacing: 16) {
                            ForEach(MealPreference.allCases, id: \.self) { preference in
                                MealPreferenceOptionView(
                                    preference: preference,
                                    isSelected: selectedPreference == preference
                                ) {
                                    _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedPreference = preference
                                    }
                                    HapticFeedback.impact(style: .light)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Non-Vegetarian Items Section (Conditional)
                        if selectedPreference == .nonVegetarian {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Things you eat as a non-vegetarian")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(hex: "#A8A8A8"))
                                    .padding(.horizontal, 20)
                                
                                FlowLayout(spacing: 12) {
                                    ForEach(MealPreference.nonVegetarianItems, id: \.self) { item in
                                        NonVegetarianItemChipView(text: item)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 16)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 16) {
                    // Save & Next Button
                    Button(action: {
                        // Save selected preference
                        basicDetails.mealPreference = selectedPreference
                        
                        HapticFeedback.impact()
                        onNext()
                    }) {
                        Text("Save & Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(selectedPreference != nil ? Color(hex: "#D89644") : Color(hex: "#D89644").opacity(0.5))
                            .cornerRadius(20)
                    }
                    .disabled(selectedPreference == nil)
                    .padding(.horizontal, 30)
                    
                    // Page Indicator
                    PageIndicatorView(currentPage: currentPage, totalPages: totalPages)
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            // Initialize with saved value if available
            if let savedPreference = basicDetails.mealPreference {
                selectedPreference = savedPreference
            }
        }
    }
}

// MARK: - Meal Preference Option View

struct MealPreferenceOptionView: View {
    let preference: MealPreference
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Radio Button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "#D89644") : Color(hex: "#C7C7CC"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#D89644"))
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Option Text
                Text(preference.displayName)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "#2C2C2E"))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color(hex: "#FDF4EB"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "#D89644") : Color(hex: "#E5E5EA"), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Non-Vegetarian Item Chip View (Informational)

struct NonVegetarianItemChipView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(Color(hex: "#A8A8A8"))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#F5F5F5"))
            .cornerRadius(16)
    }
}

#Preview {
    MealPreferencesView(
        basicDetails: .constant(BasicDetailsData()),
        onBack: {},
        onNext: {},
        onSkip: {},
        currentPage: 9,
        totalPages: 10
    )
}
