import SwiftUI

struct CreateWorkoutView: View {
    @StateObject private var viewModel = CreateWorkoutViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showExerciseSelection = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Workout Icon
                        workoutIconView
                        
                        // Input Fields
                        VStack(spacing: 24) {
                            // Name Input
                            nameInputSection
                            
                            // Description Input
                            descriptionInputSection
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
                
                // Next Button
                nextButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Set userId when view appears
            viewModel.userId = authViewModel.currentUser?.id
        }
        .fullScreenCover(isPresented: $showExerciseSelection) {
            ExerciseSelectionView(
                workoutName: viewModel.workoutName,
                workoutDescription: viewModel.workoutDescription,
                viewModel: viewModel,
                onDismiss: {
                    dismiss()
                }
            )
            .environmentObject(authViewModel)
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
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("New Workout")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Balance the layout
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color(hex: "#F5F5F7"))
    }
    
    // MARK: - Workout Icon
    
    private var workoutIconView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#FF9500"))
                .frame(width: 100, height: 100)
            
            Image(systemName: "dumbbell")
                .font(.system(size: 50, weight: .regular))
                .foregroundColor(.white)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Name Input Section
    
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NAME")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            TextField("Lower Body, Pull Day, Chest, Saturday", text: $viewModel.workoutName)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            Text("Organize by workout, muscle group, day of the week, etc")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#FF9500"))
        }
    }
    
    // MARK: - Description Input Section
    
    private var descriptionInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            TextField("Set a plan", text: $viewModel.workoutDescription, axis: .vertical)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Next Button
    
    private var nextButton: some View {
        Button(action: {
            if viewModel.canProceedToExerciseSelection() {
                showExerciseSelection = true
                HapticFeedback.impact()
            } else {
                HapticFeedback.error()
            }
        }) {
            Text("Next")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.canProceedToExerciseSelection()
                        ? Color(hex: "#FF9500")
                        : Color.gray.opacity(0.5)
                )
                .cornerRadius(12)
        }
        .disabled(!viewModel.canProceedToExerciseSelection())
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

#Preview {
    CreateWorkoutView()
}
