import Foundation
import FirebaseAnalytics

@MainActor
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {}
    
    // MARK: - Screen Tracking
    
    func trackScreenView(_ screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])
    }
    
    // MARK: - Video Tracking
    
    func trackVideoStart(workoutId: String, workoutTitle: String) {
        Analytics.logEvent("video_start", parameters: [
            "workout_id": workoutId,
            "workout_title": workoutTitle
        ])
    }
    
    func trackVideoComplete(workoutId: String, workoutTitle: String, duration: Double) {
        Analytics.logEvent("video_complete", parameters: [
            "workout_id": workoutId,
            "workout_title": workoutTitle,
            "duration_seconds": duration
        ])
    }
    
    func trackVideoProgress(workoutId: String, progress: Double) {
        Analytics.logEvent("video_progress", parameters: [
            "workout_id": workoutId,
            "progress_percentage": progress
        ])
    }
    
    // MARK: - Subscription Tracking
    
    func trackSubscriptionStart(planId: String, planName: String, price: Double) {
        Analytics.logEvent(AnalyticsEventBeginCheckout, parameters: [
            "plan_id": planId,
            "plan_name": planName,
            "value": price,
            "currency": "USD"
        ])
    }
    
    func trackSubscriptionPurchase(planId: String, planName: String, price: Double) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterTransactionID: planId,
            AnalyticsParameterItemName: planName,
            AnalyticsParameterValue: price,
            AnalyticsParameterCurrency: "USD"
        ])
    }
    
    func trackSubscriptionCancel(planId: String) {
        Analytics.logEvent("subscription_cancel", parameters: [
            "plan_id": planId
        ])
    }
    
    // MARK: - Workout Plan Tracking
    
    func trackPlanGenerated(goal: String, daysPerWeek: Int) {
        Analytics.logEvent("plan_generated", parameters: [
            "goal": goal,
            "days_per_week": daysPerWeek
        ])
    }
    
    func trackWorkoutComplete(workoutId: String, planId: String?) {
        var parameters: [String: Any] = [
            "workout_id": workoutId
        ]
        if let planId = planId {
            parameters["plan_id"] = planId
        }
        Analytics.logEvent("workout_complete", parameters: parameters)
    }
    
    // MARK: - Feature Usage Tracking
    
    func trackFeatureUsage(featureName: String, parameters: [String: Any]? = nil) {
        var eventParameters: [String: Any] = [
            "feature_name": featureName
        ]
        if let parameters = parameters {
            eventParameters.merge(parameters) { (_, new) in new }
        }
        Analytics.logEvent("feature_usage", parameters: eventParameters)
    }
    
    // MARK: - User Properties
    
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    func setUserId(_ userId: String) {
        Analytics.setUserID(userId)
    }
}


