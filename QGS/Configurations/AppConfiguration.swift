import Foundation
import SwiftUI

// MARK: - App Configuration Protocol
protocol AppConfigurationProtocol {
    var appName: String { get }
    var bundleIdentifier: String { get }
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var apiBaseURL: String { get }
    var firebaseProjectID: String { get }
    var supportsRegistration: Bool { get }
    var supportsAds: Bool { get }
    var supportedLanguages: [String] { get }
    var defaultLanguage: String { get }
    var appStoreURL: String { get }
    var supportEmail: String { get }
    var privacyPolicyURL: String { get }
    var termsOfServiceURL: String { get }
}

// MARK: - Base Configuration
class BaseAppConfiguration: AppConfigurationProtocol {
    var appName: String { "QGS" }
    var bundleIdentifier: String { "com.qgs.app" }
    var primaryColor: Color { Color.blue }
    var secondaryColor: Color { Color.gray }
    var apiBaseURL: String { 
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("API_BASE_URL not found in Info.plist")
        }
        return url
    }
    var firebaseProjectID: String { 
        guard let projectID = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_PROJECT_ID") as? String else {
            fatalError("FIREBASE_PROJECT_ID not found in Info.plist")
        }
        return projectID
    }
    var supportsRegistration: Bool { false }
    var supportsAds: Bool { false }
    var supportedLanguages: [String] { ["en", "es"] }
    var defaultLanguage: String { "en" }
    var appStoreURL: String { "" }
    var supportEmail: String { "support@qgs.com" }
    var privacyPolicyURL: String { "" }
    var termsOfServiceURL: String { "" }
}

// MARK: - QGS Configuration
class QGSConfiguration: BaseAppConfiguration {
    override var appName: String { "QGS" }
    override var bundleIdentifier: String { "com.qgs.app" }
    override var primaryColor: Color { Color.blue }
    override var supportEmail: String { "support@qgs.com" }
    override var appStoreURL: String { "https://apps.apple.com/app/qgs" }
}

// MARK: - Friendly Check-In/Out Configuration
class FriendlyConfiguration: BaseAppConfiguration {
    override var appName: String { "Friendly Check-In/Out" }
    override var bundleIdentifier: String { "com.friendly.checkinout" }
    override var primaryColor: Color { Color.green }
    override var supportsRegistration: Bool { true }
    override var supportsAds: Bool { true }
    override var supportEmail: String { "support@friendlypayroll.net" }
    override var appStoreURL: String { "https://apps.apple.com/app/friendly-checkinout" }
    override var privacyPolicyURL: String { "https://friendlypayroll.net/privacy" }
    override var termsOfServiceURL: String { "https://friendlypayroll.net/terms" }
}

// MARK: - MCS Configuration
class MCSConfiguration: BaseAppConfiguration {
    override var appName: String { "MCS" }
    override var bundleIdentifier: String { "com.mcs.app" }
    override var primaryColor: Color { Color.orange }
    override var supportEmail: String { "support@mcs.com" }
    override var appStoreURL: String { "https://apps.apple.com/app/mcs" }
}

// MARK: - App Configuration Manager
class AppConfigurationManager {
    static let shared = AppConfigurationManager()
    
    private init() {}
    
    lazy var current: AppConfigurationProtocol = {
        #if QGS_TARGET
        return QGSConfiguration()
        #elseif FRIENDLY_TARGET
        return FriendlyConfiguration()
        #elseif MCS_TARGET
        return MCSConfiguration()
        #else
        return QGSConfiguration() // Default fallback
        #endif
    }()
    
    // MARK: - Environment Detection
    var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Build Information
    var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }
    
    var versionNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }
    
    var buildConfiguration: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }
}

// MARK: - Configuration Extensions
extension AppConfigurationManager {
    var displayName: String {
        current.appName
    }
    
    var mainColor: Color {
        current.primaryColor
    }
    
    var accentColor: Color {
        current.secondaryColor
    }
    
    var canRegisterUsers: Bool {
        current.supportsRegistration
    }
    
    var shouldShowAds: Bool {
        current.supportsAds && !isDebugMode
    }
}