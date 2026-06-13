import SwiftUI

// In-session exercise logs — Trakkit (Figma: node 657-2870 AI on, 657-4535 AI off)

struct WorkoutSessionLogView: View {
    let workout: Workout
    let exercises: [Exercise]
    let userId: String
    /// Called after this screen is dismissed. `saved` is true when “End Session” persisted logs.
    var onFinished: (_ saved: Bool) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionVM: WorkoutSessionLogViewModel
    @State private var showAddExerciseHint = false
    @State private var endSessionError: String?
    @State private var showEndSessionError = false
    
    private let primaryOrange = Color(hex: "#FF9500")
    private let screenBg = Color.white
    
    init(
        workout: Workout,
        exercises: [Exercise],
        userId: String,
        onFinished: @escaping (_ saved: Bool) -> Void
    ) {
        self.workout = workout
        self.exercises = exercises
        self.userId = userId
        self.onFinished = onFinished
        _sessionVM = StateObject(wrappedValue: WorkoutSessionLogViewModel(
            workout: workout,
            exercises: exercises,
            userId: userId,
            suggestedPlansDefault: true
        ))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            screenBg.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerBar
                    
                    suggestedPlansCard
                    
                    restTimeCard
                    
                    exerciseSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 200)
            }
            
            bottomActions
            
            if sessionVM.restOverlayPresented {
                SessionRestOverlay(sessionVM: sessionVM)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(100)
            }
        }
        .animation(.easeOut(duration: 0.22), value: sessionVM.restOverlayPresented)
        .navigationBarHidden(true)
        .onAppear {
            sessionVM.startSessionTimerIfNeeded()
        }
        .onDisappear {
            sessionVM.stopSessionTimer()
        }
        .alert("Add exercises", isPresented: $showAddExerciseHint) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You can add or reorder exercises from your workout detail after this session.")
        }
        .alert("Couldn’t save session", isPresented: $showEndSessionError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(endSessionError ?? "Unknown error")
        }
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        ZStack {
            Text(workout.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1A1A1A"))
            HStack {
                Button {
                    dismiss()
                    onFinished(false)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#1A1A1A"))
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Suggested plans
    
    private var suggestedPlansCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppConstants.TrakkitAI.iconBox)
                    .frame(width: 44, height: 44)
                Image("generate")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Plans")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitAI.title)
                Text("Auto-fill sets based on your goals")
                    .font(.system(size: 13))
                    .foregroundColor(AppConstants.TrakkitAI.secondaryLabel)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: Binding(
                get: { sessionVM.suggestedPlansEnabled },
                set: { sessionVM.setSuggestedPlansEnabled($0) }
            ))
            .labelsHidden()
            .tint(AppConstants.TrakkitAI.toggleTint)
        }
        .padding(16)
        .background(
            ZStack {
                AppConstants.TrakkitAI.cardFill
                RadialGradient(
                    colors: [AppConstants.TrakkitAI.glowTopTrailing, Color.clear],
                    center: .topTrailing,
                    startRadius: 8,
                    endRadius: 180
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppConstants.TrakkitAI.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Rest time
    
    private var restTimeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Rest Time")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                    Text("Choose recovery duration")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8E8E8E"))
                }
                Spacer()
                Text("\(sessionVM.restSeconds) s")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(primaryOrange)
            }
            
            HStack(spacing: 10) {
                ForEach(WorkoutSessionLogViewModel.restOptions, id: \.self) { sec in
                    let on = sessionVM.restSeconds == sec
                    Button {
                        sessionVM.setRestSeconds(sec)
                        HapticFeedback.impact()
                    } label: {
                        Text("\(sec)s")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(on ? .white : Color(hex: "#5C5C5C"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(on ? primaryOrange : Color(hex: "#FFF5EB"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .shadow(color: on ? primaryOrange.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Note: Time is suggested on the basis of your goal, however you can change it as your preference.")
                .font(.system(size: 11))
                .foregroundColor(sessionVM.suggestedPlansEnabled ? Color(hex: "#AEAEAE") : primaryOrange.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Exercise list
    
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Exercise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                Spacer()
                Button {
                    showAddExerciseHint = true
                } label: {
                    Text("+ Add Exercise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(primaryOrange)
                }
            }
            
            ForEach(sessionVM.exercisesState) { state in
                exerciseCard(state: state)
            }
        }
    }
    
    private func exerciseCard(state: SessionExerciseLogState) -> some View {
        let expanded = sessionVM.expandedExerciseId == state.exercise.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                sessionVM.toggleExerciseExpanded(state.exercise.id)
                HapticFeedback.impact()
            } label: {
                HStack(spacing: 12) {
                    SessionLogSquareThumb(urlString: state.exercise.thumbnailURL, size: 56, cornerRadius: 10)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(state.exercise.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .multilineTextAlignment(.leading)
                        Text(sessionExerciseSubtitle(state.exercise))
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#8E8E8E"))
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#C4C4C4"))
                        .rotationEffect(.degrees(90))
                }
                .padding(12)
            }
            .buttonStyle(.plain)
            
            if expanded {
                setsGrid(exerciseId: state.exercise.id, sets: state.sets)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(expanded ? primaryOrange : Color(hex: "#E8E8E8"), lineWidth: expanded ? 1.5 : 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    private func sessionExerciseSubtitle(_ exercise: Exercise) -> String {
        let muscle = exercise.muscleGroups.first?.displayName ?? "Full Body"
        let n = exercise.name.lowercased()
        if n.contains("rowing") || (n.contains("row") && !n.contains("pull")) {
            return "\(muscle) • Hypertrophy"
        }
        if exercise.muscleGroups.contains(.cardio) {
            return "\(muscle) • Cardio"
        }
        if ExerciseCatalogFilter.recovery.matches(exercise) {
            return "\(muscle) • Recovery"
        }
        return "\(muscle) • Strength"
    }
    
    // MARK: - Sets grid
    
    private func setsGrid(exerciseId: String, sets: [SessionLogSet]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("SET")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#AEAEAE"))
                    .frame(width: 36, alignment: .leading)
                Text("WEIGHT (KG)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#AEAEAE"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("REPS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "#AEAEAE"))
                    .frame(width: 72, alignment: .leading)
                Color.clear.frame(width: 36)
            }
            
            ForEach(sets) { row in
                setRow(exerciseId: exerciseId, row: row)
            }
            
            if !sessionVM.suggestedPlansEnabled {
                Button {
                    sessionVM.addSet(forExerciseId: exerciseId)
                    HapticFeedback.impact()
                } label: {
                    Text("ADD SET")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(primaryOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(primaryOrange.opacity(0.75), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }
    
    private func setRow(exerciseId: String, row: SessionLogSet) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text("\(row.setNumber)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#1A1A1A"))
                .frame(width: 36, alignment: .leading)
            
            TextField(
                "",
                text: Binding(
                    get: {
                        sessionVM.exercisesState.first { $0.exercise.id == exerciseId }?.sets.first { $0.id == row.id }?.weightText ?? ""
                    },
                    set: { sessionVM.updateSetWeight(exerciseId: exerciseId, setId: row.id, text: $0) }
                ),
                prompt: Text("--").foregroundColor(Color(hex: "#C4C4C4"))
            )
            .keyboardType(.decimalPad)
            .font(.system(size: 15, weight: .medium))
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .background(Color(hex: "#F3F3F5"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(maxWidth: .infinity)
            
            TextField(
                "",
                text: Binding(
                    get: {
                        sessionVM.exercisesState.first { $0.exercise.id == exerciseId }?.sets.first { $0.id == row.id }?.repsText ?? ""
                    },
                    set: { sessionVM.updateSetReps(exerciseId: exerciseId, setId: row.id, text: $0) }
                ),
                prompt: Text("--").foregroundColor(Color(hex: "#C4C4C4"))
            )
            .keyboardType(.numberPad)
            .font(.system(size: 15, weight: .medium))
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .background(Color(hex: "#F3F3F5"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .frame(width: 72)
            
            Button {
                sessionVM.toggleSetCompleted(exerciseId: exerciseId, setId: row.id)
                HapticFeedback.impact()
            } label: {
                let completed = sessionVM.exercisesState.first { $0.exercise.id == exerciseId }?.sets.first { $0.id == row.id }?.completed ?? false
                ZStack {
                    if completed {
                        Circle()
                            .fill(Color(hex: "#34C759"))
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color(hex: "#D0D0D0"), lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#D8D8D8"))
                    }
                }
            }
            .frame(width: 36)
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Bottom bar
    
    private var bottomActions: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [screenBg.opacity(0), screenBg.opacity(0.95), screenBg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)

            VStack(alignment: .leading, spacing: 8) {
                Text("Session Duration")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                Text(sessionVM.sessionDurationFormatted)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(hex: "#D1D1D6"))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            
            HStack(spacing: 12) {
                Button {
                    sessionVM.toggleSessionPause()
                    HapticFeedback.impact()
                } label: {
                    Text(sessionVM.isSessionPaused ? "Resume" : "Pause")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(primaryOrange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(primaryOrange, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .disabled(sessionVM.isSaving)
                
                Button {
                    Task { await endSessionTapped() }
                } label: {
                    Group {
                        if sessionVM.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("End Session")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(primaryOrange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(sessionVM.isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(screenBg)
    }
    
    private func endSessionTapped() async {
        HapticFeedback.impact()
        do {
            try await sessionVM.commitSession()
            await MainActor.run {
                sessionVM.stopSessionTimer()
                dismiss()
                onFinished(true)
            }
        } catch {
            await MainActor.run {
                endSessionError = error.localizedDescription
                showEndSessionError = true
                HapticFeedback.error()
            }
        }
    }
}

// MARK: - Rest countdown overlay

private struct SessionRestOverlay: View {
    @ObservedObject var sessionVM: WorkoutSessionLogViewModel
    
    private let orange = Color(hex: "#FF9500")
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                restCountdownCard
                if sessionVM.restHydrationCardVisible {
                    restHydrationTipCard
                }
            }
            .padding(.horizontal, 22)
        }
    }
    
    private var restCountdownCard: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("Rest countdown!")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        HapticFeedback.impact()
                        sessionVM.dismissRestOverlay()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.92))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                
                RestSessionCountdownRing(
                    elapsedProgress: sessionVM.restElapsedProgress,
                    remainingSeconds: sessionVM.restRemainingSeconds,
                    caption: sessionVM.restCaption,
                    accent: orange
                )
                .padding(.top, 8)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#5C5C5C"))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 14, x: 0, y: 8)
            
            coachBadge
                .offset(y: -20)
        }
    }
    
    private var coachBadge: some View {
        Image("profilecircle")
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color(hex: "#0A84FF"), lineWidth: 3))
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    private var restHydrationTipCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "#34C759"))
                        .frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    HapticFeedback.impact()
                    sessionVM.dismissRestHydrationCardOnly()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            
            Text("Keep yourself hydrated")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Keep drinking water or electrolytes during rest so you stay sharp for the next set.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Fact: EAAs are a solid option during hard sessions.")
                .font(.system(size: 14, weight: .medium))
                .italic()
                .foregroundColor(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#7B61FF"),
                    Color(hex: "#5B3BE9")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

private struct RestSessionCountdownRing: View {
    let elapsedProgress: CGFloat
    let remainingSeconds: Int
    let caption: String
    let accent: Color
    
    private let ringSize: CGFloat = 172
    private let lineWidth: CGFloat = 12
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.38), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, elapsedProgress)))
                .stroke(accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 6) {
                Text(caption)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#C4C4C4"))
                    .multilineTextAlignment(.center)
                
                Text("\(remainingSeconds)")
                    .font(.system(size: 54, weight: .heavy))
                    .foregroundColor(Color(hex: "#F2F2F7"))
                    .monospacedDigit()
                
                Text("sec")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#EBEBF5").opacity(0.85))
            }
        }
        .frame(width: ringSize, height: ringSize)
    }
}

// MARK: - Thumbnail

private struct SessionLogSquareThumb: View {
    let urlString: String?
    var size: CGFloat = 56
    var cornerRadius: CGFloat = 10
    
    var body: some View {
        Group {
            if let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty, let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
    
    private var placeholder: some View {
        ZStack {
            Color(hex: "#E8E8ED")
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 22))
                .foregroundColor(Color(hex: "#AEAEAE"))
        }
    }
}

#Preview {
    let exId = "preview_lat"
    let ex = Exercise(
        id: exId,
        name: "Lats Pull Down",
        description: "Vertical pull",
        sets: 3,
        reps: 12,
        muscleGroups: [.back],
        difficultyLevel: .intermediate,
        instructions: []
    )
    WorkoutSessionLogView(
        workout: Workout(
            title: "Pull Day",
            description: "",
            category: .strength,
            difficulty: .intermediate,
            duration: 45,
            exercises: [exId],
            userId: "u1"
        ),
        exercises: [ex],
        userId: "u1",
        onFinished: { _ in }
    )
}
