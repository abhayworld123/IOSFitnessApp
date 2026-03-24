# Trakkit App - Implementation Plan & Analysis

## Overview
This document outlines what needs to be created, updated, or completed based on the Figma flow diagram and current codebase analysis.

---

## Current Implementation Status

### ✅ Completed Features

#### 1. **Authentication & Onboarding**
- **Screens:**
  - `SplashScreenView` - Splash screen with animation
  - `LoginView` - User login
  - `SignUpView` - User registration
  - `NewOnboardingView` - Multi-step onboarding flow (10 screens)
    - Screen 1: Welcome/Intro
    - Screen 2: Gender Selection (`BasicDetailsView`)
    - Screen 3: Age Selection (`AgeSelectionView`)
    - Screen 4: Weight Selection (`WeightSelectionView`)
    - Screen 5: Height Selection (`HeightSelectionView`)
    - Screen 6: Activity Level (`ActivityLevelSelectionView`)
    - Screen 7: Physical Limitations (`PhysicalLimitationsView`)
    - Screen 8: Activity Interests (`ActivityInterestsView`)
    - Screen 9: Goals Selection (`GoalsSelectionView`)
    - Screen 10: Meal Preferences (`MealPreferencesView`)

- **Services:**
  - `AuthService` - Firebase authentication
  - User data stored in Firestore `users` collection

- **Models:**
  - `User` - User profile with fitness goals
  - `BasicDetailsData` - Onboarding data collection
  - `NewOnboardingModels` - Onboarding enums and data structures

#### 2. **Dashboard**
- **Screens:**
  - `NewDashboardView` - Main dashboard
  - `DashboardHeaderView` - User header with profile
  - `StreakCardView` - Weekly activity streak
  - `DailyTrackerCardView` - Daily metrics (weight, water, sleep, steps)
  - `HowToSectionView` - Featured workout videos
  - `MyWorkoutSectionView` - Quick workout actions

- **ViewModels:**
  - `DashboardViewModel2` - Dashboard state management

- **Models:**
  - `StreakData` - Weekly activity tracking
  - `DailyMetrics` - Daily health metrics
  - `WorkoutQuickAction` - Quick action buttons

- **Status:** ⚠️ Using mock data, needs Firebase integration

#### 3. **Workout Plan System**
- **Screens:**
  - `WorkoutPlanView` - Main workout plan view
  - `PlanGeneratorView` - Plan creation wizard
  - `ExerciseDetailView` - Exercise details

- **Services:**
  - `WorkoutPlanService` - Plan CRUD operations
  - Plan generation algorithm based on goals
  - Progress tracking

- **Models:**
  - `WorkoutPlan` - Workout plan structure
  - `WorkoutDay` - Daily workout schedule

- **Status:** ✅ Functional, but needs UI enhancements

#### 4. **Workout Library**
- **Screens:**
  - `HomeView` - Workout browsing
  - `WorkoutCardView` - Workout card component
  - `VideoPlayerView` - Video playback
  - `VideoControlsView` - Video controls

- **Services:**
  - `WorkoutService` - Workout CRUD operations
  - `VideoService` - Video playback management

- **Models:**
  - `Workout` - Workout data structure
  - `Exercise` - Exercise data structure

#### 5. **Profile & Settings**
- **Screens:**
  - `ProfileView` - User profile
  - `NotificationSettingsView` - Notification preferences
  - `PrivacyPolicyView` - Privacy policy
  - `TermsOfServiceView` - Terms of service

- **Services:**
  - `NotificationService` - Notification management

#### 6. **Subscription**
- **Screens:**
  - `PaywallView` - Premium subscription paywall
  - `SubscriptionOptionsView` - Subscription plans

- **Services:**
  - `SubscriptionService` - Subscription management

- **Models:**
  - `SubscriptionStatus` - Subscription enum

---

## 🚧 Missing/Incomplete Features

### 1. **Custom Workout Creation**
**Status:** Not Implemented

**Screens Needed:**
- `CreateWorkoutView` - Main workout creation screen
- `ExerciseSelectorView` - Exercise library browser
- `WorkoutBuilderView` - Drag-and-drop workout builder
- `SetRepsInputView` - Sets/reps input for exercises
- `WorkoutPreviewView` - Preview before saving

**ViewModels Needed:**
- `CreateWorkoutViewModel` - Manage workout creation state

**Models Needed:**
- `CustomWorkout` - Custom workout structure
- `WorkoutExercise` - Exercise with sets/reps

**APIs Needed:**
- `POST /workouts/custom` - Create custom workout
- `GET /exercises` - Fetch exercise library
- `POST /exercises` - Create custom exercise (optional)

**Implementation:**
```swift
// New file: ViewModels/CreateWorkoutViewModel.swift
// New file: Views/Workout/CreateWorkoutView.swift
// New file: Views/Workout/ExerciseSelectorView.swift
// Update: Models/Workout.swift - Add custom workout support
```

---

### 2. **Exercise Library Management**
**Status:** Partially Implemented (Model exists, UI missing)

**Screens Needed:**
- `ExerciseLibraryView` - Browse all exercises
- `ExerciseDetailView` - Exercise details (exists but needs enhancement)
- `ExerciseSearchView` - Search and filter exercises
- `MyExercisesView` - User's saved/favorite exercises

**ViewModels Needed:**
- `ExerciseLibraryViewModel` - Exercise library state

**APIs Needed:**
- `GET /exercises` - Already exists in `WorkoutService`
- `GET /exercises/{id}` - Already exists
- `POST /users/{userId}/favorite-exercises` - Add to favorites
- `DELETE /users/{userId}/favorite-exercises/{exerciseId}` - Remove favorite

**Implementation:**
```swift
// New file: Views/Exercises/ExerciseLibraryView.swift
// New file: Views/Exercises/MyExercisesView.swift
// New file: ViewModels/ExerciseLibraryViewModel.swift
// Update: Services/WorkoutService.swift - Add favorites methods
```

---

### 3. **Custom Plan Generator Enhancement**
**Status:** Basic implementation exists, needs UI improvements

**Screens Needed:**
- `CustomPlanGeneratorView` - Enhanced plan generator
- `PlanPreferencesView` - User preferences for plan
- `PlanPreviewView` - Preview generated plan
- `PlanCustomizationView` - Edit generated plan

**APIs Needed:**
- `POST /workout-plans/generate` - Already exists
- `PUT /workout-plans/{id}/customize` - Customize plan
- `POST /workout-plans/{id}/duplicate` - Duplicate plan

**Implementation:**
```swift
// Update: Views/WorkoutPlan/PlanGeneratorView.swift - Enhance UI
// New file: Views/WorkoutPlan/PlanCustomizationView.swift
// Update: Services/WorkoutPlanService.swift - Add customization methods
```

---

### 4. **Progress Tracking & Analytics**
**Status:** Basic tracking exists, needs comprehensive screens

**Screens Needed:**
- `ProgressView` - Main progress dashboard
- `WeightTrackingView` - Weight history chart
- `WorkoutHistoryView` - Completed workouts history
- `StatsView` - Overall statistics
- `CalendarView` - Calendar with workout history
- `AchievementsView` - Badges and achievements

**ViewModels Needed:**
- `ProgressViewModel` - Progress tracking state
- `StatsViewModel` - Statistics calculation

**Models Needed:**
- `ProgressEntry` - Daily progress entry
- `WeightEntry` - Weight log entry
- `Achievement` - Achievement/badge model

**APIs Needed:**
- `GET /users/{userId}/progress` - Fetch progress data
- `POST /users/{userId}/progress` - Log progress entry
- `GET /users/{userId}/weight-history` - Weight tracking
- `POST /users/{userId}/weight` - Log weight
- `GET /users/{userId}/workout-history` - Completed workouts
- `GET /users/{userId}/stats` - Overall statistics
- `GET /users/{userId}/achievements` - User achievements

**Firebase Collections Needed:**
- `users/{userId}/progress` - Daily progress entries
- `users/{userId}/weightLogs` - Weight history
- `users/{userId}/workoutHistory` - Completed workouts
- `users/{userId}/achievements` - Unlocked achievements

**Implementation:**
```swift
// New file: Views/Progress/ProgressView.swift
// New file: Views/Progress/WeightTrackingView.swift
// New file: Views/Progress/WorkoutHistoryView.swift
// New file: Views/Progress/CalendarView.swift
// New file: ViewModels/ProgressViewModel.swift
// New file: Services/ProgressService.swift
// New file: Models/ProgressModels.swift
```

---

### 5. **Daily Metrics Tracking**
**Status:** UI exists, needs backend integration

**Screens Needed:**
- `DailyMetricsView` - Enhanced daily tracking
- `WaterIntakeView` - Water logging
- `SleepTrackingView` - Sleep logging
- `StepsTrackingView` - Steps logging (HealthKit integration)
- `WeightLoggingView` - Quick weight entry

**APIs Needed:**
- `POST /users/{userId}/daily-metrics` - Log daily metrics
- `GET /users/{userId}/daily-metrics/{date}` - Get metrics for date
- `GET /users/{userId}/daily-metrics` - Get metrics history

**Firebase Collections Needed:**
- `users/{userId}/dailyMetrics` - Daily metrics logs

**Implementation:**
```swift
// New file: Services/DailyMetricsService.swift
// Update: ViewModels/DashboardViewModel2.swift - Connect to Firebase
// Update: Views/Dashboard/DailyTrackerCardView.swift - Add edit functionality
```

---

### 6. **Meal/Nutrition Tracking**
**Status:** Mentioned in onboarding, not implemented

**Screens Needed:**
- `NutritionView` - Main nutrition dashboard
- `MealLoggingView` - Log meals
- `FoodSearchView` - Search food database
- `MealPlanView` - Meal planning
- `CalorieTrackingView` - Calorie intake tracking
- `MacroTrackingView` - Macro nutrients tracking

**ViewModels Needed:**
- `NutritionViewModel` - Nutrition tracking state

**Models Needed:**
- `Meal` - Meal structure
- `FoodItem` - Food database item
- `NutritionData` - Nutrition information
- `MealPlan` - Meal plan structure

**APIs Needed:**
- `GET /food/search?query={query}` - Search food database
- `POST /users/{userId}/meals` - Log meal
- `GET /users/{userId}/meals/{date}` - Get meals for date
- `GET /users/{userId}/nutrition-stats` - Nutrition statistics
- `POST /users/{userId}/meal-plans` - Create meal plan
- `GET /users/{userId}/meal-plans` - Get meal plans

**Firebase Collections Needed:**
- `foodDatabase` - Food items database
- `users/{userId}/meals` - User meal logs
- `users/{userId}/mealPlans` - User meal plans

**Implementation:**
```swift
// New file: Views/Nutrition/NutritionView.swift
// New file: Views/Nutrition/MealLoggingView.swift
// New file: Views/Nutrition/FoodSearchView.swift
// New file: ViewModels/NutritionViewModel.swift
// New file: Services/NutritionService.swift
// New file: Models/NutritionModels.swift
```

---

### 7. **Calendar & Schedule View**
**Status:** Not Implemented

**Screens Needed:**
- `CalendarView` - Monthly calendar with workouts
- `ScheduleView` - Weekly schedule view
- `DayDetailView` - Detailed day view

**ViewModels Needed:**
- `CalendarViewModel` - Calendar state management

**APIs Needed:**
- `GET /users/{userId}/schedule/{month}` - Get schedule for month
- `GET /users/{userId}/schedule/{date}` - Get schedule for specific date

**Implementation:**
```swift
// New file: Views/Calendar/CalendarView.swift
// New file: Views/Calendar/ScheduleView.swift
// New file: ViewModels/CalendarViewModel.swift
// Update: Services/WorkoutPlanService.swift - Add schedule methods
```

---

### 8. **Settings & Preferences**
**Status:** Basic settings exist, needs expansion

**Screens Needed:**
- `SettingsView` - Main settings screen
- `AccountSettingsView` - Account management
- `FitnessSettingsView` - Fitness preferences
- `UnitsSettingsView` - Unit preferences (kg/lbs, cm/ft)
- `ReminderSettingsView` - Workout reminders
- `DataExportView` - Export user data
- `DeleteAccountView` - Account deletion

**APIs Needed:**
- `PUT /users/{userId}/settings` - Update user settings
- `GET /users/{userId}/settings` - Get user settings
- `POST /users/{userId}/export-data` - Export user data
- `DELETE /users/{userId}` - Delete account

**Implementation:**
```swift
// New file: Views/Settings/SettingsView.swift
// New file: Views/Settings/AccountSettingsView.swift
// New file: Views/Settings/FitnessSettingsView.swift
// Update: Models/User.swift - Add settings structure
// Update: Services/AuthService.swift - Add settings methods
```

---

### 9. **Notifications & Reminders**
**Status:** Service exists, needs UI enhancement

**Screens Needed:**
- `NotificationsView` - Already exists, needs enhancement
- `ReminderSetupView` - Setup workout reminders
- `NotificationDetailView` - Notification details

**APIs Needed:**
- `POST /users/{userId}/reminders` - Create reminder
- `GET /users/{userId}/reminders` - Get reminders
- `PUT /users/{userId}/reminders/{id}` - Update reminder
- `DELETE /users/{userId}/reminders/{id}` - Delete reminder

**Implementation:**
```swift
// Update: Views/Notifications/NotificationsView.swift
// New file: Views/Notifications/ReminderSetupView.swift
// New file: Services/ReminderService.swift
// Update: Services/NotificationService.swift - Add reminder methods
```

---

### 10. **Social Features (If in Flow)**
**Status:** Not Implemented

**Screens Needed:**
- `CommunityView` - Community feed
- `FriendsView` - Friends list
- `LeaderboardView` - Leaderboard
- `ShareProgressView` - Share progress

**APIs Needed:**
- `GET /community/posts` - Community posts
- `POST /users/{userId}/share` - Share progress
- `GET /leaderboard` - Leaderboard data

---

## 🔧 Backend/API Requirements

### Firebase Collections Structure

```
users/
  {userId}/
    - Basic user data (email, name, etc.)
    - currentWorkoutPlanId
    - subscriptionStatus
    - settings/
      - units
      - reminders
      - notifications
    - progress/
      {date}/ - Daily progress entries
    - weightLogs/
      {logId}/ - Weight entries
    - workoutHistory/
      {workoutId}/ - Completed workouts
    - dailyMetrics/
      {date}/ - Daily metrics
    - meals/
      {mealId}/ - Meal logs
    - mealPlans/
      {planId}/ - Meal plans
    - favoriteExercises/
      {exerciseId}/ - Favorite exercises
    - achievements/
      {achievementId}/ - Unlocked achievements
    - notifications/
      {notificationId}/ - User notifications
    - reminders/
      {reminderId}/ - Workout reminders

workouts/
  {workoutId}/ - Workout data

exercises/
  {exerciseId}/ - Exercise data

workoutPlans/
  {planId}/ - Workout plans

foodDatabase/
  {foodId}/ - Food items

community/
  {postId}/ - Community posts (if social features)
```

### API Endpoints Summary

**Authentication:**
- ✅ `POST /auth/signin` - Sign in (Firebase Auth)
- ✅ `POST /auth/signup` - Sign up (Firebase Auth)
- ✅ `POST /auth/reset-password` - Reset password

**User Management:**
- ✅ `GET /users/{userId}` - Get user data
- ✅ `PUT /users/{userId}` - Update user data
- ⚠️ `PUT /users/{userId}/settings` - Update settings (needs implementation)
- ⚠️ `POST /users/{userId}/export-data` - Export data (needs implementation)
- ⚠️ `DELETE /users/{userId}` - Delete account (needs implementation)

**Workouts:**
- ✅ `GET /workouts` - Fetch workouts
- ✅ `GET /workouts/{id}` - Get workout
- ✅ `POST /workouts` - Create workout
- ⚠️ `POST /workouts/custom` - Create custom workout (needs implementation)
- ✅ `PUT /workouts/{id}` - Update workout
- ✅ `DELETE /workouts/{id}` - Delete workout

**Exercises:**
- ✅ `GET /exercises/{id}` - Get exercise
- ✅ `GET /exercises` - Fetch exercises (batch)
- ⚠️ `GET /exercises/library` - Exercise library (needs UI)
- ⚠️ `POST /users/{userId}/favorite-exercises` - Add favorite (needs implementation)
- ⚠️ `GET /users/{userId}/favorite-exercises` - Get favorites (needs implementation)

**Workout Plans:**
- ✅ `POST /workout-plans` - Create plan
- ✅ `GET /workout-plans/{userId}` - Get user plan
- ✅ `PUT /workout-plans/{id}` - Update plan
- ✅ `POST /workout-plans/generate` - Generate plan
- ⚠️ `PUT /workout-plans/{id}/customize` - Customize plan (needs implementation)
- ⚠️ `GET /users/{userId}/schedule/{month}` - Get schedule (needs implementation)

**Progress Tracking:**
- ⚠️ `GET /users/{userId}/progress` - Get progress (needs implementation)
- ⚠️ `POST /users/{userId}/progress` - Log progress (needs implementation)
- ⚠️ `GET /users/{userId}/weight-history` - Weight history (needs implementation)
- ⚠️ `POST /users/{userId}/weight` - Log weight (needs implementation)
- ⚠️ `GET /users/{userId}/workout-history` - Workout history (needs implementation)
- ⚠️ `GET /users/{userId}/stats` - Statistics (needs implementation)

**Daily Metrics:**
- ⚠️ `POST /users/{userId}/daily-metrics` - Log metrics (needs implementation)
- ⚠️ `GET /users/{userId}/daily-metrics/{date}` - Get metrics (needs implementation)

**Nutrition:**
- ⚠️ `GET /food/search` - Search food (needs implementation)
- ⚠️ `POST /users/{userId}/meals` - Log meal (needs implementation)
- ⚠️ `GET /users/{userId}/meals/{date}` - Get meals (needs implementation)
- ⚠️ `GET /users/{userId}/nutrition-stats` - Nutrition stats (needs implementation)

**Notifications:**
- ✅ `GET /users/{userId}/notifications` - Get notifications
- ⚠️ `POST /users/{userId}/reminders` - Create reminder (needs implementation)
- ⚠️ `GET /users/{userId}/reminders` - Get reminders (needs implementation)

---

## 📱 Screen Flow Priority

### Phase 1: Core Features (High Priority)
1. **Custom Workout Creation** - Complete the "New Workout" action
2. **Exercise Library** - Complete the "My Exercises" action
3. **Daily Metrics Backend** - Connect dashboard metrics to Firebase
4. **Progress Tracking** - Weight tracking and workout history
5. **Calendar View** - Navigate to calendar from streak card

### Phase 2: Enhanced Features (Medium Priority)
6. **Custom Plan Generator UI** - Enhance plan creation experience
7. **Nutrition Tracking** - Meal logging and tracking
8. **Settings Expansion** - Complete settings screens
9. **Reminders** - Workout reminder system
10. **Achievements** - Gamification features

### Phase 3: Polish & Social (Lower Priority)
11. **Analytics Dashboard** - Comprehensive stats view
12. **Social Features** - If required by flow
13. **Data Export** - Export user data
14. **Advanced Customization** - Plan customization features

---

## 🔨 Implementation Steps

### Step 1: Custom Workout Creation
1. Create `CreateWorkoutViewModel.swift`
2. Create `CreateWorkoutView.swift`
3. Create `ExerciseSelectorView.swift`
4. Update `WorkoutService.swift` - Add custom workout methods
5. Update `NewDashboardView.swift` - Connect "New Workout" action

### Step 2: Exercise Library
1. Create `ExerciseLibraryView.swift`
2. Create `MyExercisesView.swift`
3. Create `ExerciseLibraryViewModel.swift`
4. Update `WorkoutService.swift` - Add favorites methods
5. Update `NewDashboardView.swift` - Connect "My Exercises" action

### Step 3: Daily Metrics Backend
1. Create `DailyMetricsService.swift`
2. Update `DashboardViewModel2.swift` - Replace mock data with Firebase
3. Create `DailyMetricsModels.swift`
4. Update `DailyTrackerCardView.swift` - Add edit functionality

### Step 4: Progress Tracking
1. Create `ProgressService.swift`
2. Create `ProgressView.swift`
3. Create `WeightTrackingView.swift`
4. Create `WorkoutHistoryView.swift`
5. Create `ProgressModels.swift`
6. Create `ProgressViewModel.swift`

### Step 5: Calendar View
1. Create `CalendarView.swift`
2. Create `CalendarViewModel.swift`
3. Update `StreakCardView.swift` - Add navigation to calendar
4. Update `WorkoutPlanService.swift` - Add schedule methods

---

## 📝 Notes

- All Firebase operations should use Firestore
- Use `@MainActor` for ViewModels to ensure UI updates on main thread
- Implement proper error handling for all API calls
- Add loading states for all async operations
- Use SwiftUI's `async/await` for async operations
- Follow existing code patterns and architecture (MVVM)
- Add analytics tracking for new screens using `AnalyticsService`
- Ensure proper navigation flow between screens
- Test all new features with both free and premium users
- Consider HealthKit integration for steps and health data

---

## 🎯 Quick Reference

**Current Tab Structure:**
- Home (Workout browsing)
- Plan (Workout plan)
- Profile (User profile)

**Potential New Tabs:**
- Dashboard (Main dashboard - currently accessible from Home?)
- Progress (Progress tracking)
- Nutrition (Meal tracking)

**Key Services:**
- `AuthService` - Authentication
- `WorkoutService` - Workouts & Exercises
- `WorkoutPlanService` - Workout plans
- `NotificationService` - Notifications
- `SubscriptionService` - Subscriptions
- `AnalyticsService` - Analytics

**Key ViewModels:**
- `AuthViewModel` - Auth state
- `DashboardViewModel2` - Dashboard state
- `WorkoutPlanViewModel` - Plan state
- `WorkoutViewModel` - Workout state

---

*Last Updated: Based on codebase analysis and Figma flow diagram review*
