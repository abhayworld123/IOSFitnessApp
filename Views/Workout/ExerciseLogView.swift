import SwiftUI

struct ExerciseLogView: View {
    let exercise: Exercise
    let workout: Workout
    let userId: String
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ExerciseLogViewModel
    @FocusState private var focusedField: Field?
    @State private var showAddingForm: Bool = false
    
    enum Field {
        case reps, weight, restTime, note
    }
    
    init(exercise: Exercise, workout: Workout, userId: String) {
        self.exercise = exercise
        self.workout = workout
        self.userId = userId
        _viewModel = StateObject(wrappedValue: ExerciseLogViewModel(
            exercise: exercise,
            workout: workout,
            userId: userId
        ))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.savedSets.isEmpty {
                ProgressView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Screen Title
                        Text("Exercise Logs")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#1C1C1E"))
                            .padding(.top, 8)
                        
                        // Navigation Header
                        navigationHeader
                        
                        // Segmented Control
                        segmentedControl
                        
                        // Content based on state
                        if viewModel.selectedTab == .sets {
                            if viewModel.savedSets.isEmpty && !showAddingForm && !viewModel.isLoading {
                                emptyStateView
                            } else {
                                setsContentView
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadLogs()
        }
    }
    
    // MARK: - Navigation Header
    
    private var navigationHeader: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(exercise.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            Spacer()
            
            // Invisible spacer to center the title
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        HStack(spacing: 8) {
            // Sets Tab
            Button(action: {
                viewModel.selectedTab = .sets
                HapticFeedback.impact()
            }) {
                Text("Sets")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(viewModel.selectedTab == .sets ? Color(hex: "#1C1C1E") : Color(hex: "#8E8E93"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(viewModel.selectedTab == .sets ? Color.white : Color.clear)
                    .cornerRadius(12)
            }
            
            // Analyze Tab
            Button(action: {
                // Coming soon - no action
            }) {
                VStack(spacing: 4) {
                    Text("Analyze")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "#8E8E93"))
                    
                    // Coming Soon badge
                    Text("Coming Soon")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple)
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color(hex: "#DCDCDB"))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(true)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Rest Time Section (visible even in empty state)
            restTimeSection
            
            Spacer()
                .frame(height: 40)
            
            // Empty State Message
            VStack(spacing: 8) {
                Text("No sets yet!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                Text("Lets record your sets to progress")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "#8E8E93"))
                
                Text("every session")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "#8E8E93"))
            }
            .frame(maxWidth: .infinity)
            .multilineTextAlignment(.center)
            
            Spacer()
                .frame(height: 40)
            
            // Add Log Button
            Button(action: {
                showAddingForm = true
                HapticFeedback.impact()
            }) {
                Text("Add Log")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: "#FF9500"))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Sets Content View
    
    private var setsContentView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Adding new set form
            if showAddingForm || viewModel.savedSets.isEmpty {
                addingSetForm
            }
            
            // Saved sets list
            if !viewModel.savedSets.isEmpty {
                savedSetsList
                
                // Add More Sets button
                Button(action: {
                    showAddingForm = true
                    viewModel.addNewSet()
                    HapticFeedback.impact()
                }) {
                    Text("Add More Sets")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#FF9500"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "#FF9500"), lineWidth: 1)
                        )
                }
            }
        }
    }
    
    // MARK: - Adding Set Form
    
    private var addingSetForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Rest Time Section
            restTimeSection
                .padding(.bottom, 20)
            
            // Counters Section
            countersSection
                .padding(.bottom, 20)
            
            // Divider
            Divider()
                .background(Color(hex: "#E5E5EA"))
                .padding(.bottom, 20)
            
            // Note Field
            noteField
                .padding(.bottom, 20)
            
            // Done Button
            doneButton
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - Rest Time Section (standalone for reuse)
    
    private var restTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // White container with rest time input
            HStack {
                Text("Rest time between sets")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                Text("sec")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#8E8E93"))
                
                Spacer()
                
                TextField("120", value: $viewModel.restTime, format: .number)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .frame(width: 60, height: 44)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(focusedField == .restTime ? Color(hex: "#FF9500") : Color(hex: "#FF9500"), lineWidth: 2)
                    )
                    .focused($focusedField, equals: .restTime)
                    .onChange(of: viewModel.restTime) { oldValue, newValue in
                        if newValue < 0 {
                            viewModel.restTime = 0
                        }
                    }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            
            // Note text below
            Text("Note: Time is suggested on the basis of your goal, however you can change it as your preference.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "#FF9500"))
        }
    }
    
    
    // MARK: - Counters Section
    
    private var countersSection: some View {
        HStack(spacing: 20) {
            RepsCounterView(value: $viewModel.currentReps)
                .frame(maxWidth: .infinity)
            
            WeightCounterView(value: $viewModel.currentWeight)
                .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Note Field
    
    private var noteField: some View {
        TextField("Add note(Optional)", text: $viewModel.note)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(Color(hex: "#1C1C1E"))
            .frame(height: 44)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E5E5EA"), lineWidth: 1)
            )
            .focused($focusedField, equals: .note)
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        Button(action: {
            Task {
                await viewModel.validateAndSave()
                if viewModel.errorMessage == nil {
                    showAddingForm = false
                }
            }
        }) {
            Text("Done")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canSave ? Color(hex: "#FF9500") : Color(hex: "#C7C7CC"))
                .cornerRadius(12)
        }
        .disabled(!viewModel.canSave || viewModel.isLoading)
    }
    
    // MARK: - Saved Sets List
    
    private var savedSetsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Saved Sets")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            VStack(spacing: 0) {
                ForEach(Array(viewModel.savedSets.enumerated()), id: \.element.id) { index, set in
                    savedSetRow(set: set, index: index)
                    
                    if index < viewModel.savedSets.count - 1 {
                        Divider()
                            .background(Color(hex: "#E5E5EA"))
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func savedSetRow(set: ExerciseSet, index: Int) -> some View {
        HStack(alignment: .center) {
            // Left side: Set number and date
            VStack(alignment: .leading, spacing: 4) {
                Text("Set \(set.setNumber)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                if let completedAt = set.completedAt {
                    Text(formatDate(completedAt))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "#8E8E93"))
                }
            }
            
            Spacer()
            
            // Right side: Reps and Weight with colors
            HStack(spacing: 12) {
                Text("\(set.reps) Reps")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#34C759")) // Green color
                
                Text("\(String(format: "%.0f", set.weight))Kgs")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "#FF9500")) // Orange color
            }
            
            // Arrow button
            Button(action: {
                // Navigate to set details or edit
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#FF9500"))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    ExerciseLogView(
        exercise: Exercise(
            name: "Lats Pull Down",
            description: "Test exercise",
            muscleGroups: [.back],
            difficultyLevel: .intermediate,
            instructions: []
        ),
        workout: Workout(
            title: "Test Workout",
            description: "Test",
            category: .strength,
            difficulty: .intermediate,
            duration: 30
        ),
        userId: "test-user"
    )
}
