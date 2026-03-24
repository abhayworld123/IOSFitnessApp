import SwiftUI

struct AgePickerView: View {
    @Binding var selectedAge: Int?
    @State private var ageText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollOffset: CGFloat = 0
    @State private var isScrolling = false
    @State private var scrollTimer: Timer?
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    let ageRange = 5...100
    private let itemWidth: CGFloat = 90 // 70 width + 20 spacing
    
    var centerAge: Int {
        let screenCenter = UIScreen.main.bounds.width / 2
        let adjustedOffset = scrollOffset + screenCenter
        let index = Int(round(adjustedOffset / itemWidth))
        let age = 5 + index
        return max(5, min(100, age))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Validation Error Message
            if showValidationError {
                Text(validationMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            ZStack {
            // Background ScrollView with numbers
            ScrollViewReader { proxy in
                GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        // Leading spacer for centering
                        Spacer()
                            .frame(width: UIScreen.main.bounds.width / 2 - 35)
                        
                        ForEach(Array(ageRange), id: \.self) { age in
                            Text("\(age)")
                                .font(.system(size: selectedAge == age ? 32 : 24, weight: selectedAge == age ? .bold : .regular))
                                .foregroundColor(selectedAge == age ? Color.clear : Color(hex: "#C7C7CC"))
                                .frame(width: 70, height: 70)
                                .id(age)
                                .onTapGesture {
                                    isTextFieldFocused = false
                                    scrollTimer?.invalidate()
                                    isScrolling = false
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedAge = age
                                        ageText = "\(age)"
                                        HapticFeedback.impact(style: .light)
                                    }
                                }
                        }
                        
                        // Trailing spacer for centering
                        Spacer()
                            .frame(width: UIScreen.main.bounds.width / 2 - 35)
                    }
                    .padding(.vertical, 24)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: contentGeometry.frame(in: .named("scrollView")).origin.x
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scrollView")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { _ in
                            if !isScrolling && !isTextFieldFocused {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    isScrolling = true
                                }
                            }
                        }
                        .onEnded { _ in
                            // Gesture ended, but keep scrolling state until scroll stops
                        }
                )
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        let oldOffset = scrollOffset
                        scrollOffset = value
                        
                        // Detect that user is scrolling (offset changed)
                        if !isTextFieldFocused && abs(oldOffset - value) > 0.1 {
                            if !isScrolling {
                                isScrolling = true
                            }
                            
                            // Cancel previous timer
                            scrollTimer?.invalidate()
                            
                            // Set timer to detect when scrolling stops
                            scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                                // Scrolling stopped
                                DispatchQueue.main.async {
                                    let newAge = centerAge
                                    
                                    // Update the selected age and text first
                                    if ageRange.contains(newAge) {
                                        selectedAge = newAge
                                        ageText = "\(newAge)"
                                        HapticFeedback.impact(style: .light)
                                    }
                                    
                                    // Then show text again
                                    withAnimation(.easeIn(duration: 0.15)) {
                                        isScrolling = false
                                    }
                                }
                            }
                        }
                    }
                    .background(Color(hex: "#FFF5E9"))
                    .cornerRadius(16)
                    .onChange(of: selectedAge) { newAge in
                        if let age = newAge, ageRange.contains(age) {
                            if !isScrolling {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        proxy.scrollTo(age, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                    .onChange(of: ageText) { newValue in
                        // Only process text changes when user is typing
                        guard isTextFieldFocused else { return }
                        
                        // Filter to only digits
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            ageText = filtered
                        }
                        
                        // Validate age input
                        if let age = Int(filtered) {
                            if ageRange.contains(age) {
                                // Valid age
                                scrollTimer?.invalidate()
                                isScrolling = false
                                selectedAge = age
                                
                                // Hide validation error
                                withAnimation {
                                    showValidationError = false
                                }
                                HapticFeedback.impact(style: .light)
                            } else {
                                // Invalid age range
                                selectedAge = nil
                                
                                // Show validation error
                                if age < 5 {
                                    validationMessage = "Age must be at least 5 years"
                                } else if age > 100 {
                                    validationMessage = "Age must be 100 years or less"
                                }
                                
                                withAnimation {
                                    showValidationError = true
                                }
                                HapticFeedback.error()
                            }
                        } else if filtered.isEmpty {
                            // Empty input
                            selectedAge = nil
                            withAnimation {
                                showValidationError = false
                            }
                        }
                    }
                    .onAppear {
                        // Default to age 24 and scroll to it
                        if selectedAge == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                selectedAge = 24
                                ageText = "24"
                                proxy.scrollTo(24, anchor: .center)
                            }
                        } else {
                            ageText = "\(selectedAge ?? 24)"
                            proxy.scrollTo(selectedAge ?? 24, anchor: .center)
                        }
                    }
                }
            }
            
            // Fixed center selection box with text input
            ZStack {
                // Orange border - always visible
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#D89644"), lineWidth: 3)
                    .frame(width: 70, height: 70)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isScrolling ? Color.clear : Color.white)
                    )
                
                // Text input - only visible when not scrolling
                if !isScrolling {
                    TextField("", text: $ageText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "#2C2C2E"))
                        .multilineTextAlignment(.center)
                        .focused($isTextFieldFocused)
                        .frame(width: 70, height: 70)
                        .background(Color.clear)
                        .transition(.opacity)
                        .onChange(of: isTextFieldFocused) { focused in
                            if !focused {
                                if selectedAge != nil {
                                    // When keyboard dismisses, ensure we're showing the selected age
                                    ageText = "\(selectedAge!)"
                                } else if !ageText.isEmpty {
                                    // Invalid age was entered, clear it
                                    ageText = ""
                                }
                                // Hide validation error when keyboard dismisses
                                withAnimation {
                                    showValidationError = false
                                }
                            }
                        }
                }
            }
            }
            .frame(height: 120)
        }
    }
}

// Preference key to track scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


#Preview {
    AgePickerView(selectedAge: .constant(24))
        .padding()
}
