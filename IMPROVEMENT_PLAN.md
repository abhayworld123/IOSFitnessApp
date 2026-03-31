# FitnessApp iOS - Code Quality Improvement Plan

**Date Created:** 2026-03-24  
**Last Updated:** 2026-03-24  
**Status:** All phases implemented  
**Goal:** Fix all identified code quality issues, technical debt, and incomplete features in the FitnessApp iOS codebase

---

## Context

This plan addresses technical debt and code quality issues identified during a comprehensive analysis of the FitnessApp iOS codebase. The app is a full-featured fitness tracking application with authentication (Email/Google/Phone), 10-step onboarding, dashboard with streaks, workout library, and tracking features (water, steps, weight).

The codebase follows MVVM architecture with SwiftUI, Firebase (Auth, Firestore), StoreKit, and HealthKit. While functionally complete, several issues need attention before scaling.

---

## Priority Matrix

| Priority | Category | Impact | Effort |
|----------|----------|--------|--------|
| P0 | Duplicate Files | Build conflicts | Low |
| P0 | Legacy Code Cleanup | Confusion, maintenance | Low |
| P1 | Incomplete Features | User experience | Medium |
| P1 | Test Coverage | Regression prevention | High |
| P2 | Large File Refactoring | Maintainability | Medium |
| P2 | Code Quality | Developer experience | Low |
| P3 | Accessibility | App Store compliance | Medium |
| P3 | Performance | User experience | Medium |

---

## Phase 1: P0 - Duplicate Files & Legacy Cleanup

### 1.1 Delete Duplicate App Entry Files

**Files to Delete:**
- `FitnessApp/FitnessAppApp.swift` (22 lines - template stub)
- `FitnessApp/ContentView.swift` (24 lines - template stub)

**Files to Keep:**
- `App/FitnessAppApp.swift` (75 lines - production implementation)
- `App/ContentView.swift` (119 lines - production implementation)

**Verification:**
```bash
ls -la FitnessApp/FitnessAppApp.swift  # Should not exist
ls -la App/FitnessAppApp.swift         # Should exist
```

### 1.2 Delete Legacy Onboarding Files

**Files to Delete:**
- `Views/Onboarding/OnboardingView.swift` (129 lines)
- `Views/Onboarding/OnboardingPageView.swift` (66 lines)
- `Views/Onboarding/PageIndicatorView.swift` (26 lines)
- `Models/OnboardingPage.swift` (legacy model)

**Files to Keep:**
- `Views/Onboarding/NewOnboardingView.swift` (273 lines - production)
- All `*SelectionView.swift` files (new onboarding steps)

**Verification:**
```bash
grep -r "OnboardingView" --include="*.swift" | grep -v "NewOnboardingView"
# Should return no results
```

### 1.3 Delete Legacy DashboardViewModel

**Files to Delete:**
- `ViewModels/DashboardViewModel.swift` (mock data version)
- `Models/DashboardMetrics.swift` (old schema - verify first)

**Files to Keep:**
- `ViewModels/DashboardViewModel2.swift` (Firebase-backed production version)

**Verification:**
```bash
grep -r "DashboardViewModel[^2]" --include="*.swift"
# Should only find DashboardViewModel2 references
```

---

## Phase 2: P1 - Incomplete Features

### 2.1 Implement Dashboard TODO Features

**File:** `Views/Dashboard/NewDashboardView.swift`

**TODO #1 (line 204): Custom Plan Navigation**
```swift
case .customPlan:
    // TODO: Navigate to custom plan generator
    // FIX: Add navigation state and sheet
    @State private var showCustomPlan = false
    // In handleWorkoutAction:
    showCustomPlan = true
    HapticFeedback.impact()
    // Add .sheet modifier for CustomPlanGeneratorView
```

**TODO #2 (line 209): My Exercises Navigation**
```swift
case .myExercises:
    // TODO: Navigate to exercises list
    // FIX: Add navigation state and sheet
    @State private var showExercisesList = false
    // In handleWorkoutAction:
    showExercisesList = true
    HapticFeedback.impact()
    // Add .sheet modifier for ExercisesListView
```

### 2.2 Implement Water Tracking Date Picker

**File:** `Views/Water/WaterTrackingView.swift` (line 171)

```swift
// TODO: Show date picker
// FIX: Add DatePicker sheet
@State private var showDatePicker = false
@State private var selectedDate = Date()

Button(action: { showDatePicker = true }) {
    // existing code
}
.datePicker(selection: $showDatePicker, selectedDate: $selectedDate)
```

### 2.3 Fix Streak Persistence

**File:** `ViewModels/DashboardViewModel2.swift` (line 201)

```swift
// TODO: Save to Firebase
// FIX: Persist to Firestore
func toggleDayCompletion(_ day: String) async {
    // Existing toggle logic
    guard let userId = AuthAuth.currentUser?.uid else { return }
    let streakRef = db.collection("streaks").document(userId)
    try await streakRef.updateData(["completedWorkouts": completedWorkouts])
}
```

### 2.4 Add Error Alert in Exercise Selection

**File:** `Views/Workout/ExerciseSelectionView.swift` (line 332)

```swift
// TODO: Show error alert
// FIX: Add error state and alert
@State private var showErrorAlert = false
@State private var errorMessage = ""

do {
    try await viewModel.saveWorkout()
} catch {
    errorMessage = error.localizedDescription
    showErrorAlert = true
}
.alert("Save Failed", isPresented: $showErrorAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage)
}
```

### 2.5 DashboardViewModel Firebase Integration

**File:** `ViewModels/DashboardViewModel.swift`

This file should be **DELETED** (Phase 1). If any unique logic exists, migrate to DashboardViewModel2.

---

## Phase 3: P1 - Test Coverage

### 3.1 Test File Structure

```
FitnessAppTests/
├── Models/
│   ├── UserTests.swift
│   ├── WorkoutTests.swift
│   └── ExerciseTests.swift
├── ViewModels/
│   ├── AuthViewModelTests.swift
│   ├── WorkoutViewModelTests.swift
│   └── DashboardViewModel2Tests.swift
├── Services/
│   ├── AuthServiceTests.swift
│   ├── WorkoutServiceTests.swift
│   └── WaterTrackingServiceTests.swift
└── Utilities/
    └── StringValidationTests.swift

FitnessAppUITests/
├── OnboardingFlowTests.swift
├── LoginFlowTests.swift
├── DashboardTests.swift
└── ProfileFlowTests.swift
```

### 3.2 Priority Test Files

**Phase 3a - Models (Foundation):**
```swift
// UserTests.swift
@Test("User encodes to JSON")
func userEncodable() throws {
    let user = User(id: "1", email: "test@example.com", name: "Test")
    let encoded = try JSONEncoder().encode(user)
    #expect(!encoded.isEmpty)
}

// WorkoutTests.swift
@Test("Workout filters by category")
func workoutFiltering() throws {
    let workouts = Workouts.sampleData
    let strength = workouts.filter { $0.category == .strength }
    #expect(!strength.isEmpty)
}
```

**Phase 3b - ViewModels (Business Logic):**
```swift
// AuthViewModelTests.swift
@Test("Valid email passes validation")
func validEmailValidation() {
    let viewModel = AuthViewModel()
    #expect("test@example.com".isValidEmail == true)
}

@Test("Invalid email fails validation")
func invalidEmailValidation() {
    #expect("invalid".isValidEmail == false)
}
```

**Phase 3c - Services (Data Layer):**
```swift
// WorkoutServiceTests.swift
@Test("Fetch workouts returns non-empty array")
func fetchWorkouts() async throws {
    let service = WorkoutService.shared
    let workouts = try await service.fetchWorkouts()
    #expect(!workouts.isEmpty)
}
```

### 3.3 UI Test Structure

```swift
// OnboardingFlowTests.swift
func testOnboardingCompletion() {
    let app = XCUIApplication()
    app.launch()

    // Navigate through onboarding steps
    app.buttons["Get Started"].tap()
    app.buttons["Male"].tap()
    // ... complete all steps

    // Verify dashboard appears
    XCTAssertTrue(app.staticElements["Dashboard"].exists)
}
```

---

## Phase 4: P2 - Large File Refactoring

### 4.1 ProfileView.swift (665 lines)

**Extract Components:**

| Component | Lines | New File |
|-----------|-------|----------|
| EditProfileView | ~100 | `Views/Profile/EditProfileView.swift` |
| StatCard | ~50 | `Views/Profile/StatCardView.swift` |
| RecentWorkoutRow | ~40 | `Views/Profile/RecentWorkoutRow.swift` |
| SettingsRow | ~30 | `Views/Profile/SettingsRow.swift` |
| ThemeToggleRow | ~40 | `Views/Profile/ThemeToggleRow.swift` |
| ProfileActivityChart | ~150 | `Views/Profile/ProfileActivityChart.swift` (already exists) |

**Refactored ProfileView:**
```swift
struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileHeaderView(user: authViewModel.currentUser)
                StatsGridView(stats: viewModel.stats)
                RecentWorkoutsSection(workouts: viewModel.recentWorkouts)
                SettingsSection()
            }
        }
    }
}
```

### 4.2 UserWorkoutDetailView.swift (589 lines)

**Extract Components:**
- `WorkoutVideoThumbnailView`
- `ExerciseListSection`
- `WorkoutActionsView`
- `WorkoutMetadataView`

### 4.3 WaterTrackingView.swift (550 lines)

**Extract Components:**
- `WaterGoalSetupView`
- `WaterIntakeHistoryView`
- `WeeklyChartView`
- `ReminderSettingsView`

### 4.4 PlanGeneratorView.swift (515 lines)

**Extract Components:**
- `GoalSelectionSection`
- `ScheduleBuilderView`
- `ExercisePickerSection`
- `PlanPreviewView`

---

## Phase 5: P2 - Code Quality Improvements

### 5.1 Firestore Collection Constants

**New File:** `Utilities/FirestoreConstants.swift`

```swift
enum FirestoreCollections {
    static let users = "users"
    static let workouts = "workouts"
    static let exercises = "exercises"
    static let waterIntake = "waterIntake"
    static let dailyStats = "dailyStats"
    static let userProgress = "userProgress"
    static let streaks = "streaks"
    static let workoutPlans = "workoutPlans"
}

enum FirestoreFields {
    static let userId = "userId"
    static let createdAt = "createdAt"
    static let updatedAt = "updatedAt"
    static let isPremium = "isPremium"
    static let category = "category"
    static let difficulty = "difficulty"
}
```

**Update Services:**
```swift
// WorkoutService.swift
private let workoutsCollection = FirestoreCollections.workouts
```

### 5.2 Strengthen Password Validation

**File:** `Utilities/Extensions.swift`

```swift
extension String {
    var isValidPassword: Bool {
        let minLength = 8
        let hasUppercase = self.contains(where: { $0.isUppercase })
        let hasNumber = self.contains(where: { $0.isNumber })
        let hasSpecialChar = self.rangeOfCharacter(from: .punctuationCharacters) != nil
        return self.count >= minLength && hasUppercase && hasNumber && hasSpecialChar
    }
}
```

### 5.3 Onboarding Page Enum

**File:** `Models/NewOnboardingModels.swift`

```swift
enum OnboardingPage: CaseIterable {
    case intro
    case gender
    case age
    case weight
    case height
    case activityLevel
    case limitations
    case interests
    case goals
    case mealPreferences

    static var count: Int { allCases.count }

    var title: String {
        switch self {
        case .intro: return "Welcome"
        case .gender: return "Gender"
        // ...
        }
    }
}
```

---

## Phase 6: P3 - Accessibility

### 6.1 Add Accessibility Labels

**Pattern:**
```swift
Button("Save") {
    // action
}
.accessibilityLabel("Save profile changes")
.accessibilityHint("Double-tap to save your profile")
```

**Files to Update:**
- All onboarding step views
- Dashboard action buttons
- Workout card tap targets
- Profile settings toggles

### 6.2 Accessibility Traits

```swift
// For custom tab bar
CustomTabBar(...)
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Main navigation")
    .accessibilityTraits(.tabBar)
```

---

## Phase 7: P3 - Performance

### 7.1 Image Caching

For remote video thumbnails, add Kingfisher:

```swift
import Kingfisher

KFImage(URL(string: workout.thumbnailURL))
    .resizable()
    .placeholder { Color.gray }
    .cacheOriginalImage
```

### 7.2 Lazy Loading

```swift
ScrollView {
    LazyVStack(spacing: 16) {
        // Workout cards
    }
}
```

---

## Implementation Order

```
Phase 1 (P0) - Duplicate Files & Legacy Cleanup
├── 1.1 Delete duplicate app files
├── 1.2 Delete legacy onboarding
└── 1.3 Delete legacy DashboardViewModel

Phase 2 (P1) - Incomplete Features
├── 2.1 Dashboard navigation TODOs
├── 2.2 Water tracking date picker
├── 2.3 Streak persistence
├── 2.4 Exercise selection error alert
└── 2.5 Delete mock DashboardViewModel

Phase 3 (P1) - Test Coverage
├── 3.1 Model tests
├── 3.2 ViewModel tests
├── 3.3 Service tests
└── 3.4 UI tests

Phase 4 (P2) - Large File Refactoring
├── 4.1 ProfileView.swift
├── 4.2 UserWorkoutDetailView.swift
├── 4.3 WaterTrackingView.swift
└── 4.4 PlanGeneratorView.swift

Phase 5 (P2) - Code Quality
├── 5.1 Firestore constants
├── 5.2 Password validation
└── 5.3 Onboarding enum

Phase 6 (P3) - Accessibility
└── 6.1 Accessibility labels

Phase 7 (P3) - Performance
└── 7.1 Image caching
```

---

## Verification Steps

### After Phase 1:
```bash
# Verify no duplicates
find . -name "FitnessAppApp.swift" | wc -l  # Should be 1
find . -name "OnboardingView.swift"         # Should find only NewOnboardingView
```

### After Phase 2:
```bash
grep -r "// TODO" --include="*.swift" | grep -v "placeholder"
# Should show only low-priority TODOs
```

### After Phase 3:
```bash
swift test  # Should pass all tests
```

### After Phase 4:
```bash
wc -l Views/Profile/ProfileView.swift  # Should be < 200 lines
wc -l Views/Profile/*.swift            # Extracted files should exist
```

---

## Files to Modify (Summary)

| File | Action | Phase |
|------|--------|-------|
| `FitnessApp/FitnessAppApp.swift` | Delete | 1.1 |
| `FitnessApp/ContentView.swift` | Delete | 1.1 |
| `Views/Onboarding/OnboardingView.swift` | Delete | 1.2 |
| `Views/Onboarding/OnboardingPageView.swift` | Delete | 1.2 |
| `Views/Onboarding/PageIndicatorView.swift` | Delete | 1.2 |
| `Models/OnboardingPage.swift` | Delete | 1.2 |
| `ViewModels/DashboardViewModel.swift` | Delete | 1.3 |
| `Views/Dashboard/NewDashboardView.swift` | Edit | 2.1 |
| `Views/Water/WaterTrackingView.swift` | Edit | 2.2 |
| `ViewModels/DashboardViewModel2.swift` | Edit | 2.3 |
| `Views/Workout/ExerciseSelectionView.swift` | Edit | 2.4 |
| `Views/Profile/ProfileView.swift` | Edit | 4.1 |
| `Views/Workout/UserWorkoutDetailView.swift` | Edit | 4.2 |
| `Views/Water/WaterTrackingView.swift` | Edit | 4.3 |
| `Views/WorkoutPlan/PlanGeneratorView.swift` | Edit | 4.4 |
| `Utilities/Extensions.swift` | Edit | 5.2 |
| `Utilities/FirestoreConstants.swift` | Create | 5.1 |

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Breaking existing features | Run app manually after each phase |
| Test failures | Start with minimal tests, expand gradually |
| Merge conflicts | Commit after each phase |
| Asset references broken | Grep for deleted file names first |

---

## Estimated Effort

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1 | 3 deletions | 30 min |
| Phase 2 | 5 implementations | 2 hours |
| Phase 3 | Test infrastructure | 4 hours |
| Phase 4 | 4 file extractions | 3 hours |
| Phase 5 | 3 quality fixes | 1 hour |
| Phase 6 | Accessibility pass | 1 hour |
| Phase 7 | Performance | 1 hour |
| **Total** | | **~12 hours** |
