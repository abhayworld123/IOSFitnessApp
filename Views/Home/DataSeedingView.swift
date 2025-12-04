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
                    
                    Text("Add sample workouts to Firestore for testing. This will add 10 sample workouts with various categories and difficulty levels.")
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
                                Text("Seed Data")
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

