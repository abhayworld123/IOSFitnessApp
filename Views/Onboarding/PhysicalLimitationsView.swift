import SwiftUI

struct PhysicalLimitationsView: View {
    @Binding var basicDetails: BasicDetailsData
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let currentPage: Int
    let totalPages: Int
    
    @State private var customInput: String = ""
    @State private var selectedConditions: Set<String> = []
    @FocusState private var isInputFocused: Bool
    
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
                            Text("Do you have any physical limitations/conditions?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                            
                            Text("Please select any or write if you have any medical/health conditions or limitations")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#A8A8A8"))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        
                        // Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Type here", text: $customInput)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                                .focused($isInputFocused)
                                .onSubmit {
                                    addCustomCondition()
                                }
                                .padding(.bottom, 8)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(Color(hex: "#C7C7CC"))
                                        .offset(y: 8)
                                )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Predefined Conditions Chips
                        VStack(alignment: .leading, spacing: 12) {
                            let availableConditions = BasicDetailsData.predefinedConditions.filter { !selectedConditions.contains($0) }
                            
                            if !availableConditions.isEmpty {
                                FlowLayout(spacing: 12) {
                                    ForEach(availableConditions, id: \.self) { condition in
                                        ConditionChipView(
                                            text: condition,
                                            isSelected: false,
                                            onTap: {
                                                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedConditions.insert(condition)
                                                }
                                                HapticFeedback.impact(style: .light)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Selected Conditions Section
                        if !selectedConditions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                let selectedArray = Array(selectedConditions).sorted()
                                
                                FlowLayout(spacing: 12) {
                                    ForEach(selectedArray, id: \.self) { condition in
                                        SelectedConditionChipView(
                                            text: condition,
                                            onRemove: {
                                                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedConditions.remove(condition)
                                                }
                                                HapticFeedback.impact(style: .light)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 16) {
                    // Next Button
                    Button(action: {
                        // Save selected conditions
                        basicDetails.physicalLimitations = Array(selectedConditions).sorted()
                        
                        HapticFeedback.impact()
                        onNext()
                    }) {
                        Text("Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                !selectedConditions.isEmpty || !customInput.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(hex: "#D89644")
                                : Color(hex: "#D89644").opacity(0.5)
                            )
                            .cornerRadius(20)
                    }
                    .disabled(selectedConditions.isEmpty && customInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 30)
                    
                    // Page Indicator
                    PageIndicatorView(currentPage: currentPage, totalPages: totalPages)
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            // Initialize with saved values if available
            selectedConditions = Set(basicDetails.physicalLimitations)
        }
    }
    
    private func addCustomCondition() {
        let trimmed = customInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Check if already selected
        if !selectedConditions.contains(trimmed) {
            _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedConditions.insert(trimmed)
            }
            HapticFeedback.impact(style: .light)
        }
        
        // Clear input
        customInput = ""
        isInputFocused = false
    }
}

// MARK: - Condition Chip View (Selectable)

struct ConditionChipView: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Color(hex: "#2C2C2E"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "#FDF4EB"))
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected Condition Chip View

struct SelectedConditionChipView: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Color(hex: "#2C2C2E"))
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#2C2C2E"))
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "#FDF4EB"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#D89644"), lineWidth: 2)
        )
    }
}

#Preview {
    PhysicalLimitationsView(
        basicDetails: .constant(BasicDetailsData()),
        onBack: {},
        onNext: {},
        onSkip: {},
        currentPage: 6,
        totalPages: 7
    )
}
