import SwiftUI

struct ActivityInterestsView: View {
    @Binding var basicDetails: BasicDetailsData
    let onBack: () -> Void
    let onNext: () -> Void
    let onSkip: () -> Void
    let currentPage: Int
    let totalPages: Int
    
    @State private var customInput: String = ""
    @State private var selectedActivities: Set<String> = []
    @FocusState private var isInputFocused: Bool
    
    private let maxSelections = 5
    
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
                            Text("Activities you are interested in?")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                            
                            Text("Select the activities that you like doing or interested to learn. You can choose upto 5.")
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
                                    addCustomActivity()
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
                        
                        // Activity Options List (Scrollable)
                        VStack(alignment: .leading, spacing: 12) {
                            let availableActivities = BasicDetailsData.predefinedActivities.filter { !selectedActivities.contains($0) }
                            
                            ForEach(availableActivities, id: \.self) { activity in
                                ActivityOptionView(
                                    activity: activity,
                                    isSelected: selectedActivities.contains(activity),
                                    isDisabled: selectedActivities.count >= maxSelections && !selectedActivities.contains(activity),
                                    onTap: {
                                        toggleActivity(activity)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Selected Activities Section (Chips at Bottom)
                if !selectedActivities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        let selectedArray = Array(selectedActivities).sorted()
                        
                        FlowLayout(spacing: 12) {
                            ForEach(selectedArray, id: \.self) { activity in
                                SelectedActivityChipView(
                                    text: activity,
                                    onRemove: {
                                        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedActivities.remove(activity)
                                        }
                                        HapticFeedback.impact(style: .light)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 16)
                }
                
                // Bottom Section
                VStack(spacing: 16) {
                    // Next Button
                    Button(action: {
                        // Save selected activities
                        basicDetails.interestedActivities = Array(selectedActivities).sorted()
                        
                        HapticFeedback.impact()
                        onNext()
                    }) {
                        Text("Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                !selectedActivities.isEmpty || !customInput.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(hex: "#D89644")
                                : Color(hex: "#D89644").opacity(0.5)
                            )
                            .cornerRadius(20)
                    }
                    .disabled(selectedActivities.isEmpty && customInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 30)
                    
                    // Page Indicator
                    PageIndicatorView(currentPage: currentPage, totalPages: totalPages)
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            // Initialize with saved values if available
            selectedActivities = Set(basicDetails.interestedActivities)
        }
    }
    
    private func toggleActivity(_ activity: String) {
        if selectedActivities.contains(activity) {
            // Deselect
            _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedActivities.remove(activity)
            }
            HapticFeedback.impact(style: .light)
        } else {
            // Select (only if under limit)
            if selectedActivities.count < maxSelections {
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedActivities.insert(activity)
                }
                HapticFeedback.impact(style: .light)
            } else {
                HapticFeedback.error()
            }
        }
    }
    
    private func addCustomActivity() {
        let trimmed = customInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        
        // Check if already selected
        if !selectedActivities.contains(trimmed) {
            // Check limit
            if selectedActivities.count < maxSelections {
                _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedActivities.insert(trimmed)
                }
                HapticFeedback.impact(style: .light)
            } else {
                HapticFeedback.error()
            }
        }
        
        // Clear input
        customInput = ""
        isInputFocused = false
    }
}

// MARK: - Activity Option View

struct ActivityOptionView: View {
    let activity: String
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Activity Text
                Text(activity)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(isDisabled ? Color(hex: "#A8A8A8") : Color(hex: "#2C2C2E"))
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Radio Button
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color(hex: "#D89644") : Color(hex: "#D89644"), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .background(isSelected ? Color(hex: "#D89644") : Color.clear)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color(hex: "#FDF4EB"))
            .cornerRadius(12)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Selected Activity Chip View

struct SelectedActivityChipView: View {
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
    ActivityInterestsView(
        basicDetails: .constant(BasicDetailsData()),
        onBack: {},
        onNext: {},
        onSkip: {},
        currentPage: 7,
        totalPages: 8
    )
}
