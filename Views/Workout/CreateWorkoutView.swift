import SwiftUI

// New Workout — Trakkit (Figma: https://www.figma.com/design/cvRZan7u5L3sHIV727t1f1/Trakkit?node-id=650-1036 )

struct CreateWorkoutView: View {
    @StateObject private var viewModel = CreateWorkoutViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showExerciseSelection = false
    
    private let scheduleDayLetters = ["M", "T", "W", "T", "F", "S", "S"]
    private let scheduleDaySelected = Color(hex: "#4A7AFF")
    private let chipStroke = Color(hex: "#D8D8D8")
    
    var body: some View {
        ZStack {
            Color(hex: "#F5F5F7")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                cancelRow
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        titleBlock
                        
                        chooseActivitySection
                        
                        othersField
                        
                        workoutNameSection
                        
                        descriptionSection
                        
                        scheduleWorkoutCard
                        
                        recoveryTipCard
                        
                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                
                startBuildingButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.userId = authViewModel.currentUser?.id
        }
        .fullScreenCover(isPresented: $showExerciseSelection) {
            ExerciseSelectionView(
                workoutName: viewModel.workoutName,
                workoutDescription: viewModel.composedWorkoutDescriptionForFlow(),
                viewModel: viewModel,
                onDismiss: {
                    dismiss()
                }
            )
            .environmentObject(authViewModel)
        }
    }
    
    // MARK: - Header
    
    private var cancelRow: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppConstants.TrakkitHome.secondaryText)
            }
            Spacer(minLength: 0)
        }
    }
    
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Workout")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppConstants.TrakkitHome.heading)
            Text("Define your kinetic journey for today.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppConstants.TrakkitHome.secondaryText)
        }
    }
    
    // MARK: - Choose activity

    @EnvironmentObject private var categoryStore: CategoryConfigStore

    private var useRemoteActivityChips: Bool {
        categoryStore.isLoaded
            && !categoryStore.categories(for: .createWorkoutChip).isEmpty
    }
    
    private var chooseActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Activity")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#3A3A3A"))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if useRemoteActivityChips {
                        ForEach(categoryStore.categories(for: .createWorkoutChip)) { cat in
                            if let workoutCategory = cat.resolvedWorkoutCategory {
                                activityChip(
                                    title: cat.label(for: .createWorkoutChip, fallback: workoutCategory.displayName),
                                    imageURL: cat.normalizedImageURL,
                                    bundledAsset: bundledAssetName(for: cat.id),
                                    sfSymbol: cat.sfSymbolFallback ?? workoutCategory.icon,
                                    category: workoutCategory
                                )
                            }
                        }
                    } else {
                        ForEach(CategoryConfigFallback.createWorkoutChips, id: \.title) { chip in
                            activityChip(
                                title: chip.title,
                                imageURL: categoryStore.category(matching: chip.category, placement: .createWorkoutChip)?.normalizedImageURL
                                    ?? categoryStore.imageURL(forCategoryId: chip.category.rawValue),
                                bundledAsset: chip.asset,
                                sfSymbol: chip.sfSymbol,
                                category: chip.category
                            )
                        }
                    }
                }
            }
        }
        .task { await categoryStore.reload() }
    }

    private func bundledAssetName(for categoryId: String) -> String? {
        switch categoryId {
        case "strength": return "dumble"
        case "yoga": return "yoga"
        default: return nil
        }
    }
    
    private func activityChip(
        title: String,
        imageURL: URL?,
        bundledAsset: String?,
        sfSymbol: String,
        category: WorkoutCategory
    ) -> some View {
        let selected = viewModel.selectedActivityCategory == category
        return Button {
            viewModel.selectedActivityCategory = category
            HapticFeedback.impact()
        } label: {
            HStack(spacing: 8) {
                activityChipLeadingIcon(
                    imageURL: imageURL,
                    bundledAsset: bundledAsset,
                    sfSymbol: sfSymbol,
                    selected: selected
                )
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(selected ? .white : AppConstants.TrakkitHome.secondaryText)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(selected ? Color.black : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(selected ? Color.clear : chipStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func activityChipLeadingIcon(
        imageURL: URL?,
        bundledAsset: String?,
        sfSymbol: String,
        selected: Bool
    ) -> some View {
        let tint = selected ? Color.white : AppConstants.TrakkitHome.secondaryText
        if let imageURL {
            CategoryRemoteIcon(url: imageURL, fallbackSystemName: sfSymbol, size: 15, tint: tint)
        } else {
            activityChipBundledOrSymbol(bundledAsset: bundledAsset, sfSymbol: sfSymbol, tint: tint)
        }
    }

    @ViewBuilder
    private func activityChipBundledOrSymbol(bundledAsset: String?, sfSymbol: String, tint: Color) -> some View {
        if let bundledAsset, !bundledAsset.isEmpty {
            Image(bundledAsset)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(tint)
        } else {
            Image(systemName: sfSymbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(tint)
        }
    }
    
    private var othersField: some View {
        TextField("Others", text: $viewModel.othersActivityNotes)
            .font(.system(size: 16))
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
    
    // MARK: - Name & description
    
    private var workoutNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORKOUT NAME")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color(hex: "#B8B8B8"))
            TextField("e.g., Upper Body Burn, Pull Day, Back Workout", text: $viewModel.workoutName)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(Color(hex: "#B8B8B8"))
            TextField("Focus on hypertrophy and explosive movements...", text: $viewModel.workoutDescription, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(4...10)
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Schedule
    
    private var scheduleWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(AppConstants.TrakkitHome.accentOrange)
                Text("Schedule Workout")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitHome.heading)
                Spacer(minLength: 8)
                Text("SYNC")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#B8B8B8"))
                Toggle("", isOn: $viewModel.scheduleWorkoutEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "#34C759"))
            }
            
            if viewModel.scheduleWorkoutEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    Text("WEEKLY FREQUENCY")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .foregroundColor(Color(hex: "#B8B8B8"))
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { idx in
                            let selected = viewModel.selectedScheduleWeekdayIndices.contains(idx)
                            Button {
                                viewModel.toggleScheduleWeekday(idx)
                                HapticFeedback.impact()
                            } label: {
                                Text(scheduleDayLetters[idx])
                                    .font(.system(size: 14, weight: selected ? .bold : .medium))
                                    .foregroundColor(selected ? .white : Color(hex: "#5C5C5C"))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        Circle()
                                            .fill(selected ? scheduleDaySelected : Color.clear)
                                            .frame(width: 36, height: 36)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(weekdayAccessibilityLabel(idx))
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.TrakkitHome.cardCornerRadius, style: .continuous))
        .shadow(
            color: AppConstants.TrakkitHome.cardShadowColor,
            radius: AppConstants.TrakkitHome.cardShadowRadius,
            x: 0,
            y: AppConstants.TrakkitHome.cardShadowY
        )
    }
    
    private func weekdayAccessibilityLabel(_ index: Int) -> String {
        let names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        guard index < names.count else { return "Day" }
        return names[index]
    }
    
    // MARK: - Recovery tip
    
    private var recoveryTipCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppConstants.TrakkitAI.iconBox)
                    .frame(width: 44, height: 44)
                    .shadow(
                        color: AppConstants.TrakkitAI.iconBox.opacity(0.35),
                        radius: 5,
                        x: 0,
                        y: 3
                    )
                Image("generate")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Recovery Tip")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppConstants.TrakkitAI.title)
                Text("You have been working consistently for 15 days straight. I would suggest you take a recovery day to prevent any unforeseen injuries.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppConstants.TrakkitAI.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppConstants.TrakkitAI.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - CTA
    
    private var startBuildingButton: some View {
        Button(action: {
            if viewModel.canProceedToExerciseSelection() {
                showExerciseSelection = true
                HapticFeedback.impact()
            } else {
                HapticFeedback.error()
            }
        }) {
            Text("Start Building")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.canProceedToExerciseSelection()
                        ? Color(hex: "#FF9500")
                        : Color.gray.opacity(0.45)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!viewModel.canProceedToExerciseSelection())
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

#Preview {
    CreateWorkoutView()
        .environmentObject(AuthViewModel())
        .environmentObject(CategoryConfigStore.shared)
}
