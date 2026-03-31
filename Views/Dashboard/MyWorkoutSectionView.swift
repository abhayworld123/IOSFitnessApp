import SwiftUI

struct MyWorkoutSectionView: View {
    let actions: [WorkoutQuickAction]
    let userWorkouts: [Workout]
    let onActionTap: (WorkoutActionType) -> Void
    let onWorkoutTap: ((Workout) -> Void)?
    
    init(
        actions: [WorkoutQuickAction],
        userWorkouts: [Workout] = [],
        onActionTap: @escaping (WorkoutActionType) -> Void,
        onWorkoutTap: ((Workout) -> Void)? = nil
    ) {
        self.actions = actions
        self.userWorkouts = userWorkouts
        self.onActionTap = onActionTap
        self.onWorkoutTap = onWorkoutTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("My workout")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#1C1C1E"))
            
            // Content inside single card
            VStack(spacing: 0) {
                // Action Rows
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    WorkoutActionRow(action: action) {
                        onActionTap(action.action)
                    }
                    
                    // Divider between items (not after last action if no workouts)
                    if index < actions.count - 1 || !userWorkouts.isEmpty {
                        Divider()
                            .background(Color(hex: "#E5E5EA"))
                            .padding(.leading, 60) // Align with content, not icon
                    }
                }
                
                // Divider between actions and workouts
                if !userWorkouts.isEmpty && !actions.isEmpty {
                    Divider()
                        .background(Color(hex: "#E5E5EA"))
                        .padding(.leading, 60)
                }
                
                // User Created Workouts
                ForEach(Array(userWorkouts.enumerated()), id: \.element.id) { index, workout in
                    UserWorkoutRow(workout: workout) {
                        onWorkoutTap?(workout)
                    }
                    
                    // Divider between workouts
                    if index < userWorkouts.count - 1 {
                        Divider()
                            .background(Color(hex: "#E5E5EA"))
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

struct WorkoutActionRow: View {
    let action: WorkoutQuickAction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(action.iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: action.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(action.iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(action.iconColor) // Use icon color for text
                    
                    if let subtitle = action.subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#8E8E93"))
                            .italic()
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserWorkoutRow: View {
    let workout: Workout
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Checklist Icon
                Image(systemName: "square.stack")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "#8E8E93"))
                    .frame(width: 44, height: 44)
                
                // Workout Name
                Text(workout.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                    .lineLimit(1)
                
                Spacer()
                
                // Exercise Count with Arrow
                HStack(spacing: 4) {
                    Text("\(workout.exercises.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#1C1C1E"))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#C7C7CC"))
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(workout.title)
        .accessibilityHint("Opens workout details")
    }
}

#Preview {
    ScrollView {
        MyWorkoutSectionView(
            actions: [
                WorkoutQuickAction(
                    title: "New Workout",
                    subtitle: "eg: Upper body, Push plan, Leg day",
                    iconName: "plus",
                    iconColor: Color(hex: "#FF9500"),
                    action: .newWorkout
                ),
                WorkoutQuickAction(
                    title: "New Custom Plan..",
                    subtitle: nil,
                    iconName: "sparkles",
                    iconColor: Color(hex: "#AF52DE"),
                    action: .customPlan
                )
            ],
            userWorkouts: [
                Workout(
                    title: "Pull Day",
                    description: "Back and biceps",
                    category: .strength,
                    difficulty: .intermediate,
                    duration: 45,
                    exercises: ["ex1", "ex2", "ex3"]
                ),
                Workout(
                    title: "My Exercises",
                    description: "Custom exercises",
                    category: .strength,
                    difficulty: .beginner,
                    duration: 30,
                    exercises: ["ex1", "ex2"]
                )
            ],
            onActionTap: { _ in },
            onWorkoutTap: { _ in }
        )
    }
    .background(Color(hex: "#F5F5F7"))
    .previewLayout(.sizeThatFits)
}
