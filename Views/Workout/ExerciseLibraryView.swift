import SwiftUI

struct ExerciseLibraryView: View {
    let exercises: [Exercise]
    var showDismissButton: Bool = true
    @Environment(\.dismiss) var dismiss
    @State private var searchQuery = ""
    
    private var filteredExercises: [Exercise] {
        if searchQuery.isEmpty {
            return exercises
        }
        let query = searchQuery.lowercased()
        return exercises.filter { exercise in
            exercise.name.lowercased().contains(query)
                || exercise.description.lowercased().contains(query)
                || exercise.muscleGroups.contains {
                    $0.displayName.lowercased().contains(query) || $0.rawValue.lowercased().contains(query)
                }
                || exercise.difficultyLevel.displayName.lowercased().contains(query)
                || exercise.difficultyLevel.rawValue.lowercased().contains(query)
        }
    }
    
    private var groupedExercises: [(String, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { exercise in
            if exercise.muscleGroups.isEmpty {
                return "Other"
            }
            return exercise.muscleGroups
                .map(\.displayName)
                .sorted()
                .joined(separator: " · ")
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search exercises", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: "#E8E8ED"))
                .clipShape(Capsule())
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                if filteredExercises.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text(searchQuery.isEmpty ? "No exercises available" : "No exercises match your search")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: .sectionHeaders) {
                            ForEach(groupedExercises, id: \.0) { group, exercises in
                                Section {
                                    ForEach(exercises) { exercise in
                                        ExerciseLibraryRow(exercise: exercise)
                                    }
                                } header: {
                                    Text(group)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "#8E8E93"))
                                        .textCase(.uppercase)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color(hex: "#F5F5F7"))
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle("Exercise Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showDismissButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct ExerciseLibraryRow: View {
    let exercise: Exercise
    
    private var muscleGroupsLabel: String {
        exercise.muscleGroups.map(\.displayName).sorted().joined(separator: ", ")
    }
    
    var body: some View {
        NavigationLink {
            ExerciseDetailView(exercise: exercise, workout: nil)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1C1C1E"))
                
                HStack(spacing: 12) {
                    if !muscleGroupsLabel.isEmpty {
                        Label(muscleGroupsLabel, systemImage: "figure.strengthtraining.traditional")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#8E8E93"))
                            .labelStyle(.titleAndIcon)
                    }
                    
                    Label(exercise.difficultyLevel.displayName, systemImage: "chart.bar.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#8E8E93"))
                        .labelStyle(.titleAndIcon)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ExerciseLibraryView(exercises: [])
    }
}
