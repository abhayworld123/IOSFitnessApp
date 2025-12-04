# FitnessApp

A comprehensive iOS fitness application built with SwiftUI, featuring workout videos, personalized workout plans, user authentication, and subscription management.

## Features

### 🏋️ Core Features
- **Workout Library**: Browse and search through a curated collection of workout videos
- **Video Player**: Full-featured video player supporting direct URLs, YouTube, and Vimeo
- **Workout Plans**: Generate and follow personalized workout plans based on fitness goals
- **Categories**: Filter workouts by category (Strength, Cardio, Yoga, HIIT, Flexibility)
- **Difficulty Levels**: Workouts categorized by difficulty (Beginner, Intermediate, Advanced)
- **Search**: Real-time search functionality to find specific workouts

### 👤 User Features
- **Authentication**: Email/password authentication with Firebase
- **User Profiles**: Track fitness goals and subscription status
- **Onboarding**: Interactive onboarding experience for new users
- **Subscription Management**: Free and Premium subscription tiers
- **Profile Settings**: Manage notifications, privacy, and account settings

### 🎨 UI/UX
- **Modern Design**: Clean, intuitive interface with custom theming
- **Dark Mode Support**: Full support for light and dark color schemes
- **Smooth Animations**: Polished transitions and haptic feedback
- **Responsive Layout**: Grid and list view options for workouts
- **Lottie Animations**: Engaging splash screen and loading states

### 📊 Additional Features
- **Analytics**: Track user engagement and screen views
- **Network Monitoring**: Real-time network connectivity status
- **Offline Support**: Graceful handling of network issues
- **Data Seeding**: Development tools for populating sample data

## Tech Stack

- **Framework**: SwiftUI
- **Language**: Swift
- **Backend**: Firebase
  - Authentication (Firebase Auth)
  - Database (Cloud Firestore)
  - Storage (for video assets)
- **Video Playback**: AVKit, AVFoundation, WKWebView (for YouTube/Vimeo)
- **Dependencies**: 
  - Lottie (animations)
  - Firebase SDK

## Project Structure

```
FitnessApp/
├── App/
│   ├── ContentView.swift
│   └── FitnessAppApp.swift
├── FitnessApp/
│   ├── Assets.xcassets/
│   ├── ContentView.swift
│   ├── FitnessAppApp.swift
│   └── Info.plist
├── Models/
│   ├── Exercise.swift
│   ├── OnboardingPage.swift
│   ├── SubscriptionStatus.swift
│   ├── User.swift
│   ├── Workout.swift
│   └── WorkoutPlan.swift
├── Services/
│   ├── AnalyticsService.swift
│   ├── AuthService.swift
│   ├── FirebaseService.swift
│   ├── SampleData.swift
│   ├── SubscriptionService.swift
│   ├── VideoService.swift
│   ├── WorkoutPlanService.swift
│   └── WorkoutService.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── SubscriptionViewModel.swift
│   ├── VideoPlayerViewModel.swift
│   ├── WorkoutPlanViewModel.swift
│   └── WorkoutViewModel.swift
├── Views/
│   ├── Authentication/
│   │   ├── LoginView.swift
│   │   └── SignUpView.swift
│   ├── Home/
│   │   ├── DataSeedingView.swift
│   │   ├── HomeView.swift
│   │   └── WorkoutCardView.swift
│   ├── Onboarding/
│   │   ├── OnboardingPageView.swift
│   │   └── OnboardingView.swift
│   ├── Profile/
│   │   ├── NotificationSettingsView.swift
│   │   ├── PrivacyPolicyView.swift
│   │   ├── ProfileView.swift
│   │   └── TermsOfServiceView.swift
│   ├── Splash/
│   │   ├── fitness-splash.json
│   │   └── SplashScreenView.swift
│   ├── Subscription/
│   │   ├── PaywallView.swift
│   │   └── SubscriptionOptionsView.swift
│   ├── Video/
│   │   ├── VideoControlsView.swift
│   │   ├── VideoPlayerLayerView.swift
│   │   ├── VideoPlayerView.swift
│   │   └── WebVideoPlayerView.swift
│   └── WorkoutPlan/
│       ├── ExerciseDetailView.swift
│       ├── PlanGeneratorView.swift
│       └── WorkoutPlanView.swift
└── Utilities/
    ├── Constants.swift
    ├── Extensions.swift
    ├── LottieView.swift
    ├── NetworkMonitor.swift
    ├── ThemeColors.swift
    └── ThemeManager.swift
```

## Setup Instructions

### Prerequisites
- Xcode 14.0 or later
- iOS 15.0 or later
- CocoaPods or Swift Package Manager
- Firebase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd FitnessApp
   ```

2. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Create a Firestore database
   - Download `GoogleService-Info.plist` and add it to the project root
   - Ensure the file is added to your Xcode project target

3. **Install Dependencies**
   - If using CocoaPods:
     ```bash
     pod install
     ```
   - If using Swift Package Manager, add Firebase packages through Xcode:
     - FirebaseAuth
     - FirebaseFirestore
     - FirebaseStorage (if needed)

4. **Open the Project**
   - Open `FitnessApp.xcodeproj` in Xcode
   - Select your development team in Signing & Capabilities
   - Build and run the project

### Configuration

1. **Firebase Configuration**
   - Ensure `GoogleService-Info.plist` is properly configured
   - Verify Firebase services are enabled in Firebase Console

2. **App Constants**
   - Customize colors and design tokens in `Utilities/Constants.swift`
   - Update theme colors in `Utilities/ThemeColors.swift` if needed

## Usage

### For Users

1. **First Launch**: Complete the onboarding flow
2. **Sign Up/Login**: Create an account or sign in with existing credentials
3. **Browse Workouts**: Explore the workout library on the home screen
4. **Filter & Search**: Use category filters and search to find specific workouts
5. **Watch Videos**: Tap on any workout to start the video player
6. **Create Workout Plan**: Generate a personalized workout plan based on your fitness goals
7. **Upgrade to Premium**: Access premium workouts and features

### For Developers

- **Data Seeding**: Use the Data Seeding view (development only) to populate sample workouts
- **Analytics**: Screen views and user actions are automatically tracked
- **Network Status**: Monitor network connectivity in real-time

## Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel (MVVM) architecture:

- **Models**: Data structures and business logic
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Business logic and state management
- **Services**: Reusable services for API calls, authentication, etc.

### Key Components

- **AuthService**: Handles user authentication and user data management
- **WorkoutService**: Manages workout data fetching and filtering
- **WorkoutPlanService**: Handles workout plan generation and tracking
- **VideoService**: Manages video playback for different sources
- **SubscriptionService**: Handles subscription status and management
- **AnalyticsService**: Tracks user analytics and events

## Models

### User
- User profile with email, name, fitness goals
- Subscription status tracking
- Current workout plan reference

### Workout
- Workout details (title, description, category, difficulty)
- Video information (URL, source type, video ID)
- Exercise references
- Premium status

### WorkoutPlan
- Personalized workout schedules
- Weekly workout distribution
- Progress tracking
- Fitness goal alignment

## Features in Detail

### Video Player
- Supports multiple video sources:
  - Direct video URLs
  - YouTube videos (via video ID)
  - Vimeo videos (via video ID)
- Full-screen playback
- Custom video controls
- Playback state management

### Workout Plans
- AI-generated plans based on:
  - Fitness goals (Weight Loss, Muscle Gain, Flexibility, Endurance)
  - Duration preferences
  - Workouts per week
- Progress tracking
- Daily workout recommendations

### Subscription System
- Free tier: Access to basic workouts
- Premium tier: Access to all workouts and features
- Paywall integration
- Subscription status management

## Development Notes

- The app uses `@Published` properties for reactive state management
- All async operations use Swift's async/await
- Network requests include proper error handling
- UI components are reusable and modular
- Theme support allows for easy customization

## Future Enhancements

- Social features (sharing workouts, friends)
- Workout history and statistics
- Integration with health apps (HealthKit)
- Push notifications for workout reminders
- Offline video downloading
- Workout challenges and achievements

## License

[Add your license information here]

## Contributing

[Add contribution guidelines here]

## Support

For issues and questions, please [create an issue](link-to-issues) or contact [your-email].
