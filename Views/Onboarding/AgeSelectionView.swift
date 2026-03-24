import SwiftUI

struct AgeSelectionView: View {
    @Binding var basicDetails: BasicDetailsData
    let onBack: () -> Void
    let onNext: () -> Void
    let currentPage: Int
    let totalPages: Int
    
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basic details")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                            
                            Text("In order to calculate your data properly we need your basic information")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#A8A8A8"))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        
                        // Age Selection Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How old are you?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "#2C2C2E"))
                                .padding(.horizontal, 20)
                            
                            // Age Picker
                            AgePickerView(selectedAge: Binding(
                                get: { basicDetails.age },
                                set: { basicDetails.age = $0 }
                            ))
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 16)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
                
                // Bottom Section
                VStack(spacing: 16) {
                    // Next Button
                    Button(action: {
                        HapticFeedback.impact()
                        onNext()
                    }) {
                        Text("Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                basicDetails.age != nil ?
                                Color(hex: "#D89644") :
                                Color(hex: "#E0E0E0")
                            )
                            .cornerRadius(20)
                    }
                    .disabled(basicDetails.age == nil)
                    .padding(.horizontal, 30)
                    
                    // Page Indicator
                    PageIndicatorView(currentPage: currentPage, totalPages: totalPages)
                        .padding(.bottom, 30)
                }
            }
        }
    }
}

#Preview {
    AgeSelectionView(
        basicDetails: .constant(BasicDetailsData()),
        onBack: {},
        onNext: {},
        currentPage: 2,
        totalPages: 3
    )
}
