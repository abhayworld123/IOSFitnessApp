import SwiftUI

struct NewOnboardingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var basicDetails = BasicDetailsData()
    
    private let pages = NewOnboardingPage.pages
    private let totalPages = 10 // Screen 1 (intro) + Screen 2 (gender) + Screen 3 (age) + Screen 4 (weight) + Screen 5 (height) + Screen 6 (activity) + Screen 7 (physical limitations) + Screen 8 (activity interests) + Screen 9 (goals) + Screen 10 (meal preferences)
    
    var body: some View {
        ZStack {
            // Page Content
            switch currentPage {
            case 0:
                // First screen - Full screen background
                NewOnboardingScreen1View(page: pages[0]) {
                    goToNextPage()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 1:
                // Second screen - Basic Details (Gender)
                BasicDetailsView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 2:
                // Third screen - Age Selection
                AgeSelectionView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 3:
                // Fourth screen - Weight Selection
                WeightSelectionView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 4:
                // Fifth screen - Height Selection
                HeightSelectionView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 5:
                // Sixth screen - Activity Level Selection
                ActivityLevelSelectionView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    onSkip: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 6:
                // Seventh screen - Physical Limitations Selection
                PhysicalLimitationsView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    onSkip: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 7:
                // Eighth screen - Activity Interests Selection
                ActivityInterestsView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    onSkip: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 8:
                // Ninth screen - Goals Selection
                GoalsSelectionView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    onSkip: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 9:
                // Tenth screen - Meal Preferences Selection
                MealPreferencesView(
                    basicDetails: $basicDetails,
                    onBack: {
                        goToPreviousPage()
                    },
                    onNext: {
                        goToNextPage()
                    },
                    onSkip: {
                        goToNextPage()
                    },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            default:
                // Placeholder for additional screens
                Color.white
                    .overlay(
                        VStack {
                            Text("Screen \(currentPage + 1)")
                                .font(.title)
                            Button("Complete") {
                                completeOnboarding()
                            }
                            .padding()
                        }
                    )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
    }
    
    private func goToNextPage() {
        if currentPage < totalPages - 1 {
            let leavingPage = currentPage
            currentPage += 1
            if leavingPage >= 1 {
                syncBasicDetailsToFirebase()
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func goToPreviousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    private func completeOnboarding() {
        syncBasicDetailsToFirebase()
        HapticFeedback.success()
        withAnimation(.easeInOut(duration: 0.5)) {
            isPresented = false
        }
    }

    private func syncBasicDetailsToFirebase() {
        Task {
            await authViewModel.persistOnboardingDetails(basicDetails)
        }
    }
}

// MARK: - Standalone Preview Version

struct NewOnboardingPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showFullFlow = true
    
    var body: some View {
        NewOnboardingView(isPresented: $showFullFlow)
            .onChange(of: showFullFlow) { newValue in
                if !newValue {
                    dismiss()
                }
            }
    }
}

#Preview {
    NewOnboardingPreviewView()
        .environmentObject(AuthViewModel())
}
