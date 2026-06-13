import SwiftUI

struct NewOnboardingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var basicDetails = BasicDetailsData()
    @State private var persistFailureMessage: String?
    @State private var isCompleting = false
    
    private let pages = NewOnboardingPage.pages
    private let totalPages = OnboardingStep.count
    
    var body: some View {
        ZStack {
            switch currentPage {
            case 0:
                NewOnboardingScreen1View(page: pages[0]) {
                    goToNextPage()
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 1:
                BasicDetailsView(
                    basicDetails: $basicDetails,
                    onBack: { goToPreviousPage() },
                    onNext: { goToNextPage() },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 2:
                BasicVitalsOnboardingView(
                    basicDetails: $basicDetails,
                    onBack: { goToPreviousPage() },
                    onNext: { goToNextPage() },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 3:
                ActivityLevelSelectionView(
                    basicDetails: $basicDetails,
                    onBack: { goToPreviousPage() },
                    onNext: { goToNextPage() },
                    onSkip: { skipStep(.activityLevel) },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 4:
                PhysicalLimitationsView(
                    basicDetails: $basicDetails,
                    onBack: { goToPreviousPage() },
                    onNext: { goToNextPage() },
                    onSkip: { skipStep(.physicalLimitations) },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 5:
                ActivityInterestsView(
                    basicDetails: $basicDetails,
                    onBack: { goToPreviousPage() },
                    onNext: { goToNextPage() },
                    onSkip: { skipStep(.activityInterests) },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 6:
                GoalsSelectionView(
                    basicDetails: $basicDetails,
                    onBack: { goToPreviousPage() },
                    onNext: { goToNextPage() },
                    onSkip: { skipStep(.goals) },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case 7:
                MealPreferencesView(
                    basicDetails: $basicDetails,
                    onBack: { goToPreviousPage() },
                    onNext: { goToNextPage() },
                    onSkip: { skipStep(.mealPreferences) },
                    currentPage: currentPage,
                    totalPages: totalPages
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            default:
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

            if isCompleting {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView("Saving profile…")
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
        .alert("Save failed", isPresented: Binding(
            get: { persistFailureMessage != nil },
            set: { if !$0 { persistFailureMessage = nil } }
        )) {
            Button("OK") { persistFailureMessage = nil }
        } message: {
            Text(persistFailureMessage ?? "")
        }
    }
    
    private func goToNextPage(clearedFields: Set<OnboardingClearedField> = []) {
        if currentPage < totalPages - 1 {
            let leavingPage = currentPage
            currentPage += 1
            if leavingPage >= 1 {
                syncBasicDetailsToFirebase(clearedFields: clearedFields)
            }
        } else {
            completeOnboarding(clearedFields: clearedFields)
        }
    }
    
    private func goToPreviousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }

    private func skipStep(_ step: OnboardingStep) {
        var cleared = Set<OnboardingClearedField>()
        switch step {
        case .activityLevel:
            basicDetails.activityLevel = nil
            cleared.insert(.activityLevel)
        case .physicalLimitations:
            basicDetails.physicalLimitations = []
            cleared.insert(.physicalLimitations)
        case .activityInterests:
            basicDetails.interestedActivities = []
            cleared.insert(.interestedActivities)
        case .goals:
            basicDetails.fitnessGoal = nil
            cleared.insert(.fitnessGoal)
        case .mealPreferences:
            basicDetails.mealPreference = nil
            cleared.insert(.mealPreference)
        default:
            break
        }
        goToNextPage(clearedFields: cleared)
    }
    
    private func completeOnboarding(clearedFields: Set<OnboardingClearedField> = []) {
        guard !isCompleting else { return }
        isCompleting = true
        Task {
            let ok = await authViewModel.persistOnboardingDetails(
                basicDetails,
                markProfileOnboardingComplete: true,
                clearedFields: clearedFields
            )
            await MainActor.run {
                isCompleting = false
                guard ok else {
                    persistFailureMessage = "Could not save your profile. Check your connection and try again."
                    return
                }
                HapticFeedback.success()
                withAnimation(.easeInOut(duration: 0.5)) {
                    isPresented = false
                }
            }
        }
    }

    private func syncBasicDetailsToFirebase(clearedFields: Set<OnboardingClearedField> = []) {
        Task {
            _ = await authViewModel.persistOnboardingDetails(basicDetails, clearedFields: clearedFields)
        }
    }
}

// MARK: - Standalone Preview Version

struct NewOnboardingPreviewView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showFullFlow = true
    
    var body: some View {
        NewOnboardingView(isPresented: $showFullFlow)
            .onChange(of: showFullFlow) { _, newValue in
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
