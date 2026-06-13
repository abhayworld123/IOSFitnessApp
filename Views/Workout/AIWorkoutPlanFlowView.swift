import SwiftUI

/// Guided Aura flow: pick body part → AI generates 5 exercises → opens saved workout session.
struct AIWorkoutPlanFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = AIWorkoutPlanViewModel()

    let onWorkoutReady: (Workout) -> Void

    private var firstName: String {
        let raw = (authViewModel.currentUser?.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return "there" }
        return raw.split(separator: " ").first.map(String.init) ?? raw
    }

    private var personalizationName: String? {
        firstName == "there" ? nil : firstName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.TrakkitHome.background
                    .ignoresSafeArea()

                if !viewModel.isAPIConfigured {
                    configureAPIEmptyState
                } else {
                    content
                }
            }
            .navigationTitle("Aura Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
                }
            }
        }
        .onChange(of: viewModel.savedWorkout?.id) { _, newId in
            guard newId != nil, let workout = viewModel.savedWorkout else { return }
            dismiss()
            onWorkoutReady(workout)
        }
    }

    private var configureAPIEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 44))
                .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
            Text("Exercise API URL is not set")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppConstants.TrakkitHome.heading)
            Text("Add ExerciseAPIBaseURL in Info.plist to use AI workout plans.")
                .font(.subheadline)
                .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .askBodyPart:
            askBodyPartContent
        case .generating:
            generatingContent
        case .error(let message):
            errorContent(message)
        }
    }

    private var askBodyPartContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                auraHeaderRow
                greetingBubble
                bodyPartChipGrid
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var generatingContent: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppConstants.TrakkitHome.accentOrange)
            Text("Aura is building your plan…")
                .font(.headline)
                .foregroundStyle(AppConstants.TrakkitHome.heading)
            Text("Picking 5 exercises for you")
                .font(.subheadline)
                .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button("Try again") {
                viewModel.dismissError()
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
            Spacer()
        }
    }

    private var auraHeaderRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#8B5CF6"), Color(hex: "#6366F1")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Text("A")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Image(systemName: "sparkle")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Circle().fill(Color.black.opacity(0.2)))
                    .offset(x: 18, y: -18)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Aura")
                    .font(.headline)
                    .foregroundStyle(AppConstants.TrakkitHome.heading)
                Text("Personal Trainer | AI powered")
                    .font(.caption)
                    .foregroundStyle(AppConstants.TrakkitHome.secondaryText)
            }
            Spacer(minLength: 0)
        }
    }

    private var greetingBubble: some View {
        Text("Hi \(firstName)! What do you want to train today?")
            .font(.subheadline)
            .foregroundStyle(AppConstants.TrakkitHome.heading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .shadow(color: AppConstants.TrakkitHome.cardShadowColor, radius: 6, x: 0, y: 2)
            )
    }

    private var bodyPartChipGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 10
        ) {
            ForEach(MuscleGroup.aiPlanOptions, id: \.self) { group in
                Button {
                    HapticFeedback.impact()
                    Task {
                        await viewModel.selectBodyPart(
                            group,
                            userName: personalizationName,
                            userId: authViewModel.currentUser?.id
                        )
                    }
                } label: {
                    Text(group.displayName)
                        .font(.footnote.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppConstants.TrakkitHome.accentOrange.opacity(0.45), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                        )
                }
            }
        }
    }
}

#Preview {
    AIWorkoutPlanFlowView(onWorkoutReady: { _ in })
        .environmentObject(AuthViewModel())
}
