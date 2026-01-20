import Foundation
import Firebase
import FirebaseAnalytics
import FirebaseCrashlytics
import UIKit
import SwiftUI

// MARK: - Analytics Manager
/// Comprehensive analytics and crash reporting system for QGS app
/// Provides insights into user behavior, performance metrics, and error tracking

class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var isEnabled = true
    @Published var crashReportingEnabled = true
    @Published var performanceMonitoringEnabled = true
    
    private var sessionStartTime: Date?
    private var currentScreenName: String?
    private var userProperties: [String: String] = [:]
    
    // MARK: - Event Categories
    enum EventCategory: String {
        case user = "user"
        case timeTracking = "time_tracking"
        case navigation = "navigation"
        case performance = "performance"
        case error = "error"
        case engagement = "engagement"
        case feature = "feature"
        case security = "security"
    }
    
    // MARK: - Custom Events
    enum AnalyticsEvent: String {
        // User Events
        case userRegistered = "user_registered"
        case userLoggedIn = "user_logged_in"
        case userLoggedOut = "user_logged_out"
        case profileUpdated = "profile_updated"
        
        // Time Tracking Events
        case timeRecordCreated = "time_record_created"
        case entryRecorded = "entry_recorded"
        case exitRecorded = "exit_recorded"
        case recordEditedOffline = "record_edited_offline"
        case bulkRecordsSync = "bulk_records_sync"
        
        // Navigation Events
        case screenViewed = "screen_viewed"
        case tabChanged = "tab_changed"
        case deepLinkOpened = "deep_link_opened"
        
        // Feature Usage
        case locationPermissionGranted = "location_permission_granted"
        case locationPermissionDenied = "location_permission_denied"
        case notificationPermissionGranted = "notification_permission_granted"
        case biometricAuthEnabled = "biometric_auth_enabled"
        case darkModeToggled = "dark_mode_toggled"
        
        // Performance Events
        case appLaunchTime = "app_launch_time"
        case networkRequestTime = "network_request_time"
        case cacheHit = "cache_hit"
        case cacheMiss = "cache_miss"
        case syncCompleted = "sync_completed"
        case syncFailed = "sync_failed"
        
        // Error Events
        case networkError = "network_error"
        case locationError = "location_error"
        case authenticationError = "authentication_error"
        case dataCorruption = "data_corruption"
        case crashRecovered = "crash_recovered"
        
        // Engagement Events
        case sessionDuration = "session_duration"
        case featureDiscovered = "feature_discovered"
        case helpPageViewed = "help_page_viewed"
        case feedbackSubmitted = "feedback_submitted"
        case notificationOpened = "notification_opened"
        
        var category: EventCategory {
            switch self {
            case .userRegistered, .userLoggedIn, .userLoggedOut, .profileUpdated:
                return .user
            case .timeRecordCreated, .entryRecorded, .exitRecorded, .recordEditedOffline, .bulkRecordsSync:
                return .timeTracking
            case .screenViewed, .tabChanged, .deepLinkOpened:
                return .navigation
            case .appLaunchTime, .networkRequestTime, .cacheHit, .cacheMiss, .syncCompleted, .syncFailed:
                return .performance
            case .networkError, .locationError, .authenticationError, .dataCorruption, .crashRecovered:
                return .error
            case .sessionDuration, .featureDiscovered, .helpPageViewed, .feedbackSubmitted, .notificationOpened:
                return .engagement
            case .locationPermissionGranted, .locationPermissionDenied, .notificationPermissionGranted, .biometricAuthEnabled, .darkModeToggled:
                return .feature
            }
        }
    }
    
    private init() {
        setupAnalytics()
        setupCrashReporting()
        setupPerformanceMonitoring()
        startSession()
        
        logInfo("AnalyticsManager initialized", category: .general)
    }
    
    // MARK: - Setup Methods
    
    private func setupAnalytics() {
        // Set default user properties
        setUserProperty("platform", value: "iOS")
        setUserProperty("app_version", value: AppConfigurationManager.shared.versionNumber)
        setUserProperty("device_model", value: UIDevice.current.model)
        setUserProperty("ios_version", value: UIDevice.current.systemVersion)
        
        // Enable analytics collection
        Analytics.setAnalyticsCollectionEnabled(isEnabled)
        
        logInfo("Firebase Analytics configured", category: .general)
    }
    
    private func setupCrashReporting() {
        // Set up Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(crashReportingEnabled)
        
        // Set user identifier for crash reports
        if let userId = UserManager.shared.getEmployeeId {
            Crashlytics.crashlytics().setUserID(userId)
        }
        
        // Set custom keys for crash reports
        Crashlytics.crashlytics().setCustomValue(AppConfigurationManager.shared.versionNumber, forKey: "app_version")
        Crashlytics.crashlytics().setCustomValue(AppConfigurationManager.shared.buildNumber, forKey: "build_number")
        Crashlytics.crashlytics().setCustomValue(UIDevice.current.model, forKey: "device_model")
        
        logInfo("Firebase Crashlytics configured", category: .general)
    }
    
    private func setupPerformanceMonitoring() {
        // Performance monitoring is automatically enabled with Firebase Performance
        // Additional configuration can be added here if needed
        
        logInfo("Firebase Performance Monitoring configured", category: .general)
    }
    
    // MARK: - Session Management
    
    func startSession() {
        sessionStartTime = Date()
        
        trackEvent(.appLaunchTime, parameters: [
            "launch_time": Date().timeIntervalSince1970,
            "memory_usage": getCurrentMemoryUsage(),
            "disk_space": getAvailableDiskSpace()
        ])
        
        logInfo("Analytics session started", category: .general)
    }
    
    func endSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        
        trackEvent(.sessionDuration, parameters: [
            "duration_seconds": sessionDuration,
            "duration_minutes": sessionDuration / 60,
            "end_time": Date().timeIntervalSince1970
        ])
        
        sessionStartTime = nil
        
        logInfo("Analytics session ended", category: .general, metadata: [
            "duration": "\(Int(sessionDuration))s"
        ])
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any] = [:]) {
        guard isEnabled else { return }
        
        var enrichedParameters = parameters
        enrichedParameters["category"] = event.category.rawValue
        enrichedParameters["timestamp"] = Date().timeIntervalSince1970
        enrichedParameters["session_id"] = getSessionId()
        
        // Add user context if available
        if let userId = SessionManager.shared.userId {
            enrichedParameters["user_id"] = userId
        }
        
        if let currentScreen = currentScreenName {
            enrichedParameters["current_screen"] = currentScreen
        }
        
        // Track with Firebase Analytics
        Analytics.logEvent(event.rawValue, parameters: enrichedParameters)
        
        // Log for debugging
        logDebug("Analytics event tracked", category: .general, metadata: [
            "event": event.rawValue,
            "category": event.category.rawValue,
            "parameters": enrichedParameters.description
        ])
    }
    
    func trackScreenView(_ screenName: String, className: String? = nil) {
        currentScreenName = screenName
        
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: className ?? screenName
        ])
        
        trackEvent(.screenViewed, parameters: [
            "screen_name": screenName,
            "screen_class": className ?? screenName
        ])
    }
    
    // MARK: - Time Tracking Analytics
    
    func trackTimeRecordEvent(
        type: String,
        projectName: String?,
        location: [String: Double]?,
        isOffline: Bool = false
    ) {
        let event: AnalyticsEvent = type == "e" ? .entryRecorded : .exitRecorded
        
        var parameters: [String: Any] = [
            "record_type": type,
            "is_offline": isOffline
        ]
        
        if let projectName = projectName {
            parameters["project_name"] = projectName
        }
        
        if let location = location {
            parameters["has_location"] = true
            parameters["latitude"] = location["latitude"] ?? 0
            parameters["longitude"] = location["longitude"] ?? 0
        }
        
        trackEvent(event, parameters: parameters)
        
        // Track general time record created event
        trackEvent(.timeRecordCreated, parameters: parameters)
    }
    
    func trackSyncEvent(success: Bool, recordsCount: Int, duration: TimeInterval, error: String? = nil) {
        let event: AnalyticsEvent = success ? .syncCompleted : .syncFailed
        
        var parameters: [String: Any] = [
            "success": success,
            "records_count": recordsCount,
            "duration_seconds": duration
        ]
        
        if let error = error {
            parameters["error_message"] = error
        }
        
        trackEvent(event, parameters: parameters)
    }
    
    // MARK: - User Analytics
    
    func trackUserRegistration(method: String, projectType: String?) {
        var parameters: [String: Any] = [
            "registration_method": method
        ]
        
        if let projectType = projectType {
            parameters["project_type"] = projectType
        }
        
        trackEvent(.userRegistered, parameters: parameters)
    }
    
    func trackUserLogin(method: String, success: Bool, error: String? = nil) {
        var parameters: [String: Any] = [
            "login_method": method,
            "success": success
        ]
        
        if let error = error {
            parameters["error_message"] = error
        }
        
        trackEvent(.userLoggedIn, parameters: parameters)
    }
    
    // MARK: - Feature Usage Analytics
    
    func trackFeatureUsage(_ feature: String, action: String, metadata: [String: Any] = [:]) {
        var parameters = metadata
        parameters["feature"] = feature
        parameters["action"] = action
        
        trackEvent(.featureDiscovered, parameters: parameters)
    }
    
    func trackPermissionRequest(_ permission: String, granted: Bool) {
        let event: AnalyticsEvent
        
        switch permission {
        case "location":
            event = granted ? .locationPermissionGranted : .locationPermissionDenied
        case "notifications":
            event = .notificationPermissionGranted
        default:
            return
        }
        
        trackEvent(event, parameters: [
            "permission_type": permission,
            "granted": granted
        ])
    }
    
    // MARK: - Performance Analytics
    
    func trackNetworkRequest(
        endpoint: String,
        method: String,
        duration: TimeInterval,
        success: Bool,
        cacheHit: Bool = false,
        error: String? = nil
    ) {
        trackEvent(.networkRequestTime, parameters: [
            "endpoint": endpoint,
            "method": method,
            "duration_ms": duration * 1000,
            "success": success,
            "cache_hit": cacheHit,
            "error": error as Any
        ])
        
        if cacheHit {
            trackEvent(.cacheHit, parameters: ["endpoint": endpoint])
        } else {
            trackEvent(.cacheMiss, parameters: ["endpoint": endpoint])
        }
    }
    
    func trackAppPerformance() {
        let memoryUsage = getCurrentMemoryUsage()
        let diskSpace = getAvailableDiskSpace()
        let appLaunchTime = getAppLaunchTime()
        
        Analytics.logEvent("app_performance", parameters: [
            "memory_usage_mb": memoryUsage,
            "available_disk_gb": diskSpace,
            "launch_time_ms": appLaunchTime
        ])
    }
    
    // MARK: - Error and Crash Reporting
    
    func trackError(_ error: Error, context: String, fatal: Bool = false) {
        let errorInfo: [String: Any] = [
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code,
            "error_description": error.localizedDescription,
            "context": context,
            "fatal": fatal
        ]
        
        // Track with Analytics
        trackEvent(.networkError, parameters: errorInfo) // Generalize based on error type
        
        // Report to Crashlytics
        Crashlytics.crashlytics().record(error: error)
        Crashlytics.crashlytics().setCustomValue(context, forKey: "error_context")
        Crashlytics.crashlytics().setCustomValue(fatal, forKey: "is_fatal")
        
        if fatal {
            Crashlytics.crashlytics().log("Fatal error occurred: \(error.localizedDescription)")
        }
        
        logError("Error tracked", category: .general, metadata: [
            "error": error.localizedDescription,
            "context": context,
            "fatal": fatal
        ])
    }
    
    func trackNonFatalIssue(_ message: String, metadata: [String: Any] = [:]) {
        // Log to Crashlytics
        Crashlytics.crashlytics().log(message)
        
        for (key, value) in metadata {
            Crashlytics.crashlytics().setCustomValue(value, forKey: key)
        }
        
        // Create a non-fatal error
        let error = NSError(domain: "QGSApp", code: 1001, userInfo: [
            NSLocalizedDescriptionKey: message,
            "metadata": metadata
        ])
        
        Crashlytics.crashlytics().record(error: error)
    }
    
    // MARK: - User Properties
    
    func setUserProperty(_ name: String, value: String?) {
        userProperties[name] = value
        Analytics.setUserProperty(value, forName: name)
        
        if let value = value {
            Crashlytics.crashlytics().setCustomValue(value, forKey: name)
        }
    }
    
    func setUserId(_ userId: String) {
        Analytics.setUserID(userId)
        Crashlytics.crashlytics().setUserID(userId)
        setUserProperty("user_id", value: userId)
    }
    
    // MARK: - Custom Dimensions and Metrics
    
    func trackCustomMetric(_ name: String, value: Double) {
        Analytics.logEvent("custom_metric", parameters: [
            "metric_name": name,
            "metric_value": value,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackBusinessMetric(_ name: String, value: Double, currency: String = "USD") {
        Analytics.logEvent("business_metric", parameters: [
            "metric_name": name,
            "value": value,
            "currency": currency
        ])
    }
    
    // MARK: - A/B Testing Support
    
    func trackExperiment(_ experimentName: String, variant: String, outcome: String) {
        Analytics.logEvent("experiment_outcome", parameters: [
            "experiment_name": experimentName,
            "variant": variant,
            "outcome": outcome
        ])
    }
    
    // MARK: - Privacy and Consent
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        isEnabled = enabled
        Analytics.setAnalyticsCollectionEnabled(enabled)
        
        if enabled {
            logInfo("Analytics enabled", category: .general)
        } else {
            logInfo("Analytics disabled", category: .general)
        }
    }
    
    func setCrashReportingEnabled(_ enabled: Bool) {
        crashReportingEnabled = enabled
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enabled)
    }
    
    func setPerformanceMonitoringEnabled(_ enabled: Bool) {
        performanceMonitoringEnabled = enabled
        // Configure Firebase Performance monitoring if needed
    }
    
    // MARK: - Helper Methods
    
    private func getSessionId() -> String {
        return sessionStartTime?.timeIntervalSince1970.description ?? "unknown"
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // MB
        }
        
        return 0
    }
    
    private func getAvailableDiskSpace() -> Double {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return Double(capacity) / 1024.0 / 1024.0 / 1024.0 // GB
            }
        } catch {
            // Handle error
        }
        return 0
    }
    
    private func getAppLaunchTime() -> Double {
        // This would need to be calculated from app launch to this point
        // For now, return a placeholder
        return 0
    }
    
    // MARK: - Debugging and Testing
    
    func debugAnalytics() -> [String: Any] {
        return [
            "is_enabled": isEnabled,
            "crash_reporting_enabled": crashReportingEnabled,
            "performance_monitoring_enabled": performanceMonitoringEnabled,
            "session_start_time": sessionStartTime?.timeIntervalSince1970 as Any,
            "current_screen": currentScreenName as Any,
            "user_properties": userProperties,
            "memory_usage_mb": getCurrentMemoryUsage(),
            "disk_space_gb": getAvailableDiskSpace()
        ]
    }
    
    func testCrashReporting() {
        trackNonFatalIssue("Test crash report", metadata: [
            "test": true,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
}

// MARK: - Analytics Extensions for ViewModels
extension AnalyticsManager {
    
    // Convenience methods for common tracking scenarios
    func trackViewModelAction(_ viewModel: String, action: String, success: Bool, error: String? = nil) {
        var parameters: [String: Any] = [
            "view_model": viewModel,
            "action": action,
            "success": success
        ]
        
        if let error = error {
            parameters["error"] = error
        }
        
        trackEvent(.featureDiscovered, parameters: parameters)
    }
    
    func trackFormSubmission(_ formName: String, success: Bool, validationErrors: [String] = []) {
        var parameters: [String: Any] = [
            "form_name": formName,
            "success": success,
            "has_validation_errors": !validationErrors.isEmpty
        ]
        
        if !validationErrors.isEmpty {
            parameters["validation_errors"] = validationErrors.joined(separator: ", ")
        }
        
        trackEvent(.featureDiscovered, parameters: parameters)
    }
}

// MARK: - SwiftUI View Extensions
extension View {
    func trackScreenView(_ screenName: String, className: String? = nil) -> some View {
        self.onAppear {
            AnalyticsManager.shared.trackScreenView(screenName, className: className)
        }
    }
    
    func trackButtonTap(_ buttonName: String, metadata: [String: Any] = [:]) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                var parameters = metadata
                parameters["button_name"] = buttonName
                AnalyticsManager.shared.trackEvent(.featureDiscovered, parameters: parameters)
            }
        )
    }
}