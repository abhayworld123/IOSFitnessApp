import SwiftUI

struct ExerciseSelectionView: View {
    let workoutName: String
    let workoutDescription: String
    @ObservedObject var viewModel: CreateWorkoutViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let onDismiss: (() -> Void)?
    let existingWorkout: Workout?
    @State private var showSuccessAlert = false
    @State private var isSaving = false
    
    init(workoutName: String, workoutDescription: String, viewModel: CreateWorkoutViewModel, existingWorkout: Workout? = nil, onDismiss: (() -> Void)? = nil) {
        self.workoutName = workoutName
        self.workoutDescription = workoutDescription
        self.viewModel = viewModel
        self.existingWorkout = existingWorkout
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        exerciseSelectionContent
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                doneButtonBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarHidden(true)
        .onAppear {
            // Set userId when view appears
            viewModel.userId = authViewModel.currentUser?.id
            
            // Load existing workout if provided
            if let existing = existingWorkout {
                viewModel.loadExistingWorkout(existing)
            }
            
            if viewModel.allExercises.isEmpty {
                Task {
                    await viewModel.fetchExercises()
                }
            }
        }
        .alert(existingWorkout != nil ? "Workout Updated!" : "Workout Created!", isPresented: $showSuccessAlert) {
            Button("OK") {
                if existingWorkout == nil {
                    viewModel.reset()
                    dismiss()
                    // Also dismiss the parent CreateWorkoutView
                    onDismiss?()
                } else {
                    dismiss()
                }
                
                // Post notification to refresh dashboard
                if existingWorkout != nil {
                    NotificationCenter.default.post(name: NSNotification.Name("WorkoutUpdated"), object: nil)
                } else {
                    NotificationCenter.default.post(name: NSNotification.Name("WorkoutCreated"), object: nil)
                }
            }
        } message: {
            Text(existingWorkout != nil 
                 ? "Your workout '\(workoutName)' has been updated successfully."
                 : "Your workout '\(workoutName)' has been created successfully.")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
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
            
            Text(workoutName)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Balance the layout
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color(hex: "#F5F5F7"))
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search exercise name", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: viewModel.searchQuery) { newValue in
                    viewModel.searchExercises(query: newValue)
                }
            
            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                    viewModel.searchExercises(query: "")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "#E8E8ED"))
        .clipShape(Capsule())
    }
    
    // MARK: - Selected + picker
    
    private var exerciseSelectionContent: some View {
        VStack(spacing: 0) {
            if !viewModel.selectedExercisesList.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.selectedExercisesList) { exercise in
                            ExerciseSelectionRow(
                                exercise: exercise,
                                isSelected: true,
                                onTap: {
                                    viewModel.toggleExerciseSelection(exercise.id)
                                    HapticFeedback.impact()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .frame(maxHeight: 220)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.22))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            
            pickerRegion
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private var pickerRegion: some View {
        if viewModel.allExercises.isEmpty {
            emptyCatalogView
        } else if viewModel.filteredExercises.isEmpty {
            pickerEmptyMessage("Try a different search term.")
        } else if viewModel.pickerExercises.isEmpty {
            pickerEmptyMessage(
                viewModel.searchQuery.isEmpty
                    ? "All exercises are in your workout."
                    : "All matching exercises are in your workout."
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.pickerExercises) { exercise in
                        ExerciseSelectionRow(
                            exercise: exercise,
                            isSelected: false,
                            onTap: {
                                viewModel.toggleExerciseSelection(exercise.id)
                                HapticFeedback.impact()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func pickerEmptyMessage(_ message: String) -> some View {
        VStack {
            Spacer(minLength: 0)
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack {
            Spacer(minLength: 0)
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading exercises...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.top, 16)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty catalog (no data at all)
    
    private var emptyCatalogView: some View {
        VStack {
            Spacer(minLength: 0)
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Exercises Found")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 16)
            
            Text("No exercises available. Please add exercises to the database.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Done
    
    private var doneButtonBar: some View {
        Button(action: {
            saveWorkout()
        }) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isSaving ? "Saving..." : "Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                viewModel.canSaveWorkout() && !isSaving
                    ? Color(hex: "#FF9500")
                    : Color.gray.opacity(0.5)
            )
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSaveWorkout() || isSaving)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color(hex: "#F5F5F7"))
    }
    
    // MARK: - Save Workout
    
    private func saveWorkout() {
        isSaving = true
        HapticFeedback.impact()
        
        Task {
            do {
                _ = try await viewModel.createWorkout()
                await MainActor.run {
                    isSaving = false
                    showSuccessAlert = true
                    AnalyticsService.shared.trackFeatureUsage(featureName: "workout_created", parameters: [
                        "workout_name": workoutName,
                        "exercise_count": viewModel.selectedExercises.count
                    ])
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    HapticFeedback.error()
                    // TODO: Show error alert
                    print("Failed to create workout: \(error)")
                }
            }
        }
    }
}

// MARK: - Exercise Selection Row

struct ExerciseSelectionRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#FF9500"))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color(hex: "#FF9500"), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseSelectionView(
        workoutName: "Pull Day",
        workoutDescription: "Back and biceps workout",
        viewModel: CreateWorkoutViewModel(),
        existingWorkout: nil,
        onDismiss: nil
    )
}
