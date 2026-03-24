import SwiftUI

struct DataSeedingView: View {
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var isSeeding = false
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppConstants.Colors.background(colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 60))
                        .foregroundColor(AppConstants.Colors.primary)
                    
                    Text("Seed Sample Data")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppConstants.Colors.textPrimary(colorScheme: colorScheme))
                    
                    Text("Add sample data to Firestore for testing. Seed workouts or exercises from JSON files.")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.Colors.textSecondary(colorScheme: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppConstants.Colors.success)
                            Text("Data seeded successfully!")
                                .foregroundColor(AppConstants.Colors.success)
                        }
                        .padding()
                        .background(AppConstants.Colors.success.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task {
                            isSeeding = true
                            showSuccess = false
                            await workoutViewModel.seedSampleData()
                            isSeeding = false
                            showSuccess = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if isSeeding {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Seed Workouts")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppConstants.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.Design.cornerRadius)
                    }
                    .disabled(isSeeding)
                    .opacity(isSeeding ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        Task {
                            isSeeding = true
                            showSuccess = false
                            do {
                                try await WorkoutService.shared.seedExercisesFromJSON()
                                isSeeding = false
                                showSuccess = true
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    dismiss()
                                }
                            } catch {
                                isSeeding = false
                                print("Error seeding exercises: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        HStack {
                            if isSeeding {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Seed Exercises from JSON")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "#FF9500"))
                        .foregroundColor(.white)
                        .cornerRadius(AppConstants.Design.cornerRadius)
                    }
                    .disabled(isSeeding)
                    .opacity(isSeeding ? 0.6 : 1.0)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Seed Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DataSeedingView()
}

