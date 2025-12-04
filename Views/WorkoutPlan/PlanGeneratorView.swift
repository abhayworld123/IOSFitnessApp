import SwiftUI

struct PlanGeneratorView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentStep = 0
    @State private var selectedGoal: FitnessGoal?
    @State private var selectedLevel: DifficultyLevel = .beginner
    @State private var selectedDays: Int = 3
    @State private var selectedDuration: Int = 30
    @State private var selectedEquipment: EquipmentAvailability = .basic
    @State private var showPreview = false
    @State private var generatedPlan: WorkoutPlan?
    
    private let steps = ["Goal", "Level", "Days", "Duration", "Equipment"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                if showPreview, let plan = generatedPlan {
                    planPreviewView(plan: plan)
                } else {
                    questionnaireView
                }
            }
            .navigationTitle("Create Workout Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                            HapticFeedback.impact(style: .light)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Questionnaire View
    
    private var questionnaireView: some View {
        VStack(spacing: 0) {
            // Progress Indicator
            progressIndicator
            
            ScrollView {
                VStack(spacing: 24) {
                    // Step Content
                    Group {
                        switch currentStep {
                        case 0:
                            goalSelectionView
                        case 1:
                            levelSelectionView
                        case 2:
                            daysSelectionView
                        case 3:
                            durationSelectionView
                        case 4:
                            equipmentSelectionView
                        default:
                            EmptyView()
                        }
                    }
                    .transition(.slide)
                    
                    // Next/Generate Button
                    Button(action: handleNext) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(currentStep == steps.count - 1 ? "Generate Plan" : "Next")
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
                    .disabled(viewModel.isLoading || !canProceed)
                    .opacity((viewModel.isLoading || !canProceed) ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? AppConstants.Colors.primary : AppConstants.Colors.textSecondary.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? AppConstants.Colors.primary : AppConstants.Colors.textSecondary.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Text("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppConstants.Colors.textSecondary)
        }
        .padding(.vertical, 16)
        .background(AppConstants.Colors.cardBackground)
    }
    
    // MARK: - Goal Selection
    
    private var goalSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's your fitness goal?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    GoalCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        selectedGoal = goal
                        HapticFeedback.impact()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Level Selection
    
    private var levelSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What's your experience level?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach([DifficultyLevel.beginner, .intermediate, .advanced], id: \.self) { level in
                    LevelCard(
                        level: level,
                        isSelected: selectedLevel == level
                    ) {
                        selectedLevel = level
                        HapticFeedback.impact()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Days Selection
    
    private var daysSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How many days per week?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach([3, 4, 5, 6, 7], id: \.self) { days in
                    DaysCard(
                        days: days,
                        isSelected: selectedDays == days
                    ) {
                        selectedDays = days
                        HapticFeedback.impact()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Duration Selection
    
    private var durationSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferred workout duration?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach([20, 30, 45, 60], id: \.self) { minutes in
                    DurationCard(
                        minutes: minutes,
                        isSelected: selectedDuration == minutes
                    ) {
                        selectedDuration = minutes
                        HapticFeedback.impact()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Equipment Selection
    
    private var equipmentSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What equipment do you have?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppConstants.Colors.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                ForEach(EquipmentAvailability.allCases, id: \.self) { equipment in
                    EquipmentCard(
                        equipment: equipment,
                        isSelected: selectedEquipment == equipment
                    ) {
                        selectedEquipment = equipment
                        HapticFeedback.impact()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Plan Preview
    
    private func planPreviewView(plan: WorkoutPlan) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Your Workout Plan")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppConstants.Colors.textPrimary)
                    .padding(.top, 20)
                
                Text(plan.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppConstants.Colors.primary)
                
                VStack(alignment: .leading, spacing: 16) {
                    PlanInfoRow(icon: "target", title: "Goal", value: plan.goal.displayName)
                    PlanInfoRow(icon: "calendar", title: "Days per week", value: "\(plan.workoutsPerWeek)")
                    PlanInfoRow(icon: "clock", title: "Duration", value: "\(plan.durationWeeks) weeks")
                }
                .padding()
                .background(AppConstants.Colors.cardBackground)
                .cornerRadius(AppConstants.Design.cornerRadius)
                .padding(.horizontal, 20)
                
                Button(action: {
                    Task {
                        if let userId = authViewModel.currentUser?.id {
                            do {
                                try await WorkoutPlanService.shared.createPlan(plan)
                                viewModel.currentPlan = plan
                                dismiss()
                            } catch {
                                viewModel.errorMessage = "Failed to save plan"
                            }
                        }
                    }
                }) {
                    Text("Start This Plan")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppConstants.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.Design.cornerRadius)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return selectedGoal != nil
        default:
            return true
        }
    }
    
    private func handleNext() {
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
            HapticFeedback.impact(style: .light)
        } else {
            // Generate plan
            guard let goal = selectedGoal else { return }
            
            Task {
                await viewModel.generatePlan(
                    goal: goal,
                    experienceLevel: selectedLevel,
                    daysPerWeek: selectedDays,
                    durationMinutes: selectedDuration,
                    equipment: selectedEquipment
                )
                
                if let plan = viewModel.currentPlan {
                    generatedPlan = plan
                    withAnimation {
                        showPreview = true
                    }
                }
            }
        }
    }
}

// MARK: - Selection Cards

struct GoalCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.primary)
                
                Text(goal.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.Design.cornerRadius)
                    .stroke(isSelected ? Color.clear : AppConstants.Colors.textSecondary.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct LevelCard: View {
    let level: DifficultyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(level.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct DaysCard: View {
    let days: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text("\(days)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.primary)
                
                Text("days")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppConstants.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct DurationCard: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text("\(minutes)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.primary)
                
                Text("minutes")
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : AppConstants.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct EquipmentCard: View {
    let equipment: EquipmentAvailability
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(equipment.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppConstants.Colors.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? AppConstants.Colors.primary : AppConstants.Colors.cardBackground)
            .cornerRadius(AppConstants.Design.cornerRadius)
        }
    }
}

struct PlanInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppConstants.Colors.primary)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(AppConstants.Colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppConstants.Colors.textPrimary)
        }
    }
}

#Preview {
    PlanGeneratorView()
        .environmentObject(AuthViewModel())
}

