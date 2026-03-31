import Foundation
import SwiftUI

// MARK: - New Onboarding Page Model

struct NewOnboardingPage: Identifiable {
    let id = UUID()
    let logoIcon: String // SF Symbol or custom icon name
    let backgroundImage: String // Asset name
    let title: String
    let subtitle: String
    let buttonText: String
    let pageIndex: Int
    
    static let pages: [NewOnboardingPage] = [
        NewOnboardingPage(
            logoIcon: "dumbbell.fill", // Will be replaced with custom icon
            backgroundImage: "background_onboarding1",
            title: "Consistency is the\nkey to progress.",
            subtitle: "Let's track your fitness journey now!",
            buttonText: "Start tracking",
            pageIndex: 0
        )
        // Additional pages can be added here
    ]
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case intro = 0
    case gender = 1
    case age = 2
    case weight = 3
    case height = 4
    case activityLevel = 5
    case physicalLimitations = 6
    case activityInterests = 7
    case goals = 8
    case mealPreferences = 9
    
    static var count: Int { allCases.count }
}

// MARK: - Gender Selection

enum Gender: String, Codable, CaseIterable {
    case male
    case female
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
    
    var iconName: String {
        switch self {
        case .male: return "MaleIcon_onboarding"
        case .female: return "FemaleIcon_onboardin2"
        }
    }
}

// MARK: - Activity Level

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "chair"
    case light = "some_movement"
    case moderate = "gym_occasional"
    case active = "lifestyle"
    case veryActive = "gym_rat"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Chair is my primary workout"
        case .light: return "Some movement, no structured workouts"
        case .moderate: return "Gym knows your face not your name"
        case .active: return "Fitness is part of the lifestyle"
        case .veryActive: return "Practically a gym rat"
        }
    }
}

// MARK: - Meal Preference

enum MealPreference: String, Codable, CaseIterable {
    case vegan = "vegan"
    case vegetarian = "vegetarian"
    case nonVegetarian = "nonVegetarian"
    
    var displayName: String {
        switch self {
        case .vegan:
            return "Vegan"
        case .vegetarian:
            return "Vegetarian"
        case .nonVegetarian:
            return "Non-Vegetarian"
        }
    }
    
    // Non-vegetarian food items (informational)
    static let nonVegetarianItems: [String] = [
        "Eggs",
        "Chicken",
        "Buff",
        "Lamb",
        "Fish",
        "Turkey",
        "Duck",
        "Rabbit",
        "Horse",
        "Goat",
        "Camel"
    ]
}

// MARK: - Basic Details Data

struct BasicDetailsData: Codable {
    var gender: Gender?
    var age: Int?
    var weight: Double? // in kg
    var weightUnit: WeightUnit = .kg
    var height: Double? // in cm
    var heightUnit: HeightUnit = .cm
    var fitnessGoal: FitnessGoal?
    var activityLevel: ActivityLevel?
    var physicalLimitations: [String] = []
    var interestedActivities: [String] = []
    var mealPreference: MealPreference?
    
    // Predefined physical limitations/conditions
    static let predefinedConditions: [String] = [
        "Disc herniation",
        "Shoulder pain",
        "Thyroid",
        "Constipation",
        "Knee Pain",
        "Tennis Elbow",
        "PCOS",
        "Neck stiffness",
        "High blood pressure",
        "Heart condition",
        "Asthma",
        "Migraine",
        "Anxiety",
        "Poor flexibility"
    ]
    
    // Predefined activities
    static let predefinedActivities: [String] = [
        "Running",
        "Strength training",
        "Swimming",
        "Walking",
        "Badminton",
        "Hiking/Trekking",
        "Cycling"
    ]
}

// MARK: - Height Unit

enum HeightUnit: String, Codable, CaseIterable {
    case cm = "CM"
    case ftIn = "FT/IN"
    
    var displayName: String {
        return self.rawValue
    }
    
    // Convert cm to feet and inches
    static func cmToFeetInches(_ cm: Double) -> (feet: Int, inches: Int) {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
    
    // Convert feet and inches to cm
    static func feetInchesToCm(feet: Int, inches: Int) -> Double {
        let totalInches = Double(feet * 12 + inches)
        return totalInches * 2.54
    }
    
    // Format height for display
    func formatHeight(_ cm: Double) -> String {
        switch self {
        case .cm:
            return String(format: "%.0f", cm)
        case .ftIn:
            let (feet, inches) = Self.cmToFeetInches(cm)
            return "\(feet)'\(inches)\""
        }
    }
    
    // Parse height from string
    func parseHeight(_ text: String) -> Double? {
        switch self {
        case .cm:
            return Double(text)
        case .ftIn:
            // Parse format like "5'10"", "5'10", "510", or "5 10"
            let cleaned = text.replacingOccurrences(of: "'", with: " ")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespaces)
            
            // Try to split by space or extract digits
            let components = cleaned.split(separator: " ").map { String($0) }
            
            if components.count == 2 {
                // Format: "5 10" or "5'10"
                if let feet = Int(components[0]), let inches = Int(components[1]) {
                    return Self.feetInchesToCm(feet: feet, inches: inches)
                }
            } else if cleaned.count >= 2 {
                // Format: "510" (first digit is feet, rest is inches)
                let feetStr = String(cleaned.prefix(1))
                let inchesStr = String(cleaned.dropFirst())
                if let feet = Int(feetStr), let inches = Int(inchesStr) {
                    return Self.feetInchesToCm(feet: feet, inches: inches)
                }
            }
            return nil
        }
    }
    
    // Range for each unit (in cm internally)
    var range: ClosedRange<Double> {
        switch self {
        case .cm:
            return 100...220
        case .ftIn:
            return 100...220 // Same range, just displayed differently
        }
    }
}

// MARK: - Weight Unit

enum WeightUnit: String, Codable, CaseIterable {
    case kg = "KG"
    case lbs = "LBS"
    
    var displayName: String {
        return self.rawValue
    }
    
    // Conversion methods
    func convert(_ value: Double, to unit: WeightUnit) -> Double {
        if self == unit { return value }
        
        switch (self, unit) {
        case (.kg, .lbs):
            return value * 2.20462
        case (.lbs, .kg):
            return value / 2.20462
        default:
            return value
        }
    }
    
    // Range for each unit
    var range: ClosedRange<Double> {
        switch self {
        case .kg:
            return 30...200
        case .lbs:
            return 66...440
        }
    }
    
    var defaultValue: Double {
        switch self {
        case .kg:
            return 70.0
        case .lbs:
            return 154.0
        }
    }
}
