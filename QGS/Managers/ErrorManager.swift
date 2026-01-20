import Foundation
import SwiftUI

// MARK: - App Error Protocol
protocol AppError: Error, LocalizedError {
    var code: String { get }
    var category: ErrorCategory { get }
    var severity: ErrorSeverity { get }
    var userMessage: String { get }
    var technicalMessage: String { get }
    var metadata: [String: Any]? { get }
    var recoveryAction: ErrorRecoveryAction? { get }
}

// MARK: - Error Category
enum ErrorCategory: String, CaseIterable {
    case network = "Network"
    case authentication = "Authentication"
    case database = "Database"
    case location = "Location"
    case permission = "Permission"
    case validation = "Validation"
    case business = "Business"
    case system = "System"
    case ui = "UI"
    case sync = "Sync"
    
    var logCategory: LogCategory {
        switch self {
        case .network: return .network
        case .authentication: return .authentication
        case .database: return .database
        case .location: return .location
        case .permission: return .security
        case .validation: return .general
        case .business: return .general
        case .system: return .general
        case .ui: return .ui
        case .sync: return .sync
        }
    }
}

// MARK: - Error Severity
enum ErrorSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var logLevel: LogLevel {
        switch self {
        case .low: return .warning
        case .medium: return .error
        case .high: return .error
        case .critical: return .critical
        }
    }
    
    var shouldReportToRemote: Bool {
        switch self {
        case .low: return false
        case .medium: return AppConfigurationManager.shared.isProduction
        case .high: return true
        case .critical: return true
        }
    }
}

// MARK: - Error Recovery Action
enum ErrorRecoveryAction {
    case retry
    case refresh
    case logout
    case restart
    case contact
    case ignore
    case custom(title: String, action: () -> Void)
    
    var title: String {
        switch self {
        case .retry: return NSLocalizedString("error.action.retry", value: "Retry", comment: "")
        case .refresh: return NSLocalizedString("error.action.refresh", value: "Refresh", comment: "")
        case .logout: return NSLocalizedString("error.action.logout", value: "Logout", comment: "")
        case .restart: return NSLocalizedString("error.action.restart", value: "Restart App", comment: "")
        case .contact: return NSLocalizedString("error.action.contact", value: "Contact Support", comment: "")
        case .ignore: return NSLocalizedString("error.action.ignore", value: "Dismiss", comment: "")
        case .custom(let title, _): return title
        }
    }
}

// MARK: - Generic App Error
struct GenericAppError: AppError {
    let code: String
    let category: ErrorCategory
    let severity: ErrorSeverity
    let userMessage: String
    let technicalMessage: String
    let metadata: [String: Any]?
    let recoveryAction: ErrorRecoveryAction?
    
    var errorDescription: String? {
        userMessage
    }
    
    var failureReason: String? {
        technicalMessage
    }
    
    init(
        code: String,
        category: ErrorCategory,
        severity: ErrorSeverity,
        userMessage: String,
        technicalMessage: String? = nil,
        metadata: [String: Any]? = nil,
        recoveryAction: ErrorRecoveryAction? = nil
    ) {
        self.code = code
        self.category = category
        self.severity = severity
        self.userMessage = userMessage
        self.technicalMessage = technicalMessage ?? userMessage
        self.metadata = metadata
        self.recoveryAction = recoveryAction
    }
}

// MARK: - App Network Errors
enum AppNetworkError: String, CaseIterable {
    case noConnection = "NET_001"
    case timeout = "NET_002"
    case invalidResponse = "NET_003"
    case serverError = "NET_004"
    case unauthorized = "NET_005"
    case forbidden = "NET_006"
    case notFound = "NET_007"
    case rateLimited = "NET_008"
    case invalidURL = "NET_009"
    case parseError = "NET_010"
    
    func toAppError(metadata: [String: Any]? = nil) -> AppError {
        switch self {
        case .noConnection:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .medium,
                userMessage: NSLocalizedString("error.network.no_connection", value: "No internet connection. Please check your network settings.", comment: ""),
                technicalMessage: "Network connection is not available",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .timeout:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .medium,
                userMessage: NSLocalizedString("error.network.timeout", value: "Request timed out. Please try again.", comment: ""),
                technicalMessage: "Network request timed out",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .unauthorized:
            return GenericAppError(
                code: self.rawValue,
                category: .authentication,
                severity: .high,
                userMessage: NSLocalizedString("error.auth.unauthorized", value: "Your session has expired. Please log in again.", comment: ""),
                technicalMessage: "Authentication token is invalid or expired",
                metadata: metadata,
                recoveryAction: .logout
            )
        case .serverError:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .high,
                userMessage: NSLocalizedString("error.network.server_error", value: "Server error occurred. Please try again later.", comment: ""),
                technicalMessage: "Server returned an error response",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .forbidden:
            return GenericAppError(
                code: self.rawValue,
                category: .permission,
                severity: .high,
                userMessage: NSLocalizedString("error.permission.forbidden", value: "You don't have permission to perform this action.", comment: ""),
                technicalMessage: "Access forbidden - insufficient permissions",
                metadata: metadata,
                recoveryAction: .contact
            )
        case .notFound:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .medium,
                userMessage: NSLocalizedString("error.network.not_found", value: "Requested resource not found.", comment: ""),
                technicalMessage: "Resource not found (404)",
                metadata: metadata,
                recoveryAction: .refresh
            )
        case .rateLimited:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .medium,
                userMessage: NSLocalizedString("error.network.rate_limited", value: "Too many requests. Please wait and try again.", comment: ""),
                technicalMessage: "Rate limit exceeded",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .invalidURL:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .high,
                userMessage: NSLocalizedString("error.network.invalid_url", value: "Invalid request. Please contact support.", comment: ""),
                technicalMessage: "Invalid URL configuration",
                metadata: metadata,
                recoveryAction: .contact
            )
        case .parseError:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .medium,
                userMessage: NSLocalizedString("error.network.parse_error", value: "Unable to process server response. Please try again.", comment: ""),
                technicalMessage: "Failed to parse server response",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .invalidResponse:
            return GenericAppError(
                code: self.rawValue,
                category: .network,
                severity: .medium,
                userMessage: NSLocalizedString("error.network.invalid_response", value: "Invalid server response. Please try again.", comment: ""),
                technicalMessage: "Server returned invalid response format",
                metadata: metadata,
                recoveryAction: .retry
            )
        }
    }
}

// MARK: - Database Errors
enum DatabaseError: String, CaseIterable {
    case saveFailed = "DB_001"
    case loadFailed = "DB_002"
    case deleteFailed = "DB_003"
    case migrationFailed = "DB_004"
    case corruptedData = "DB_005"
    case diskFull = "DB_006"
    
    func toAppError(metadata: [String: Any]? = nil) -> AppError {
        switch self {
        case .saveFailed:
            return GenericAppError(
                code: self.rawValue,
                category: .database,
                severity: .high,
                userMessage: NSLocalizedString("error.database.save_failed", value: "Failed to save data. Please try again.", comment: ""),
                technicalMessage: "Database save operation failed",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .loadFailed:
            return GenericAppError(
                code: self.rawValue,
                category: .database,
                severity: .medium,
                userMessage: NSLocalizedString("error.database.load_failed", value: "Failed to load data. Please refresh.", comment: ""),
                technicalMessage: "Database load operation failed",
                metadata: metadata,
                recoveryAction: .refresh
            )
        case .deleteFailed:
            return GenericAppError(
                code: self.rawValue,
                category: .database,
                severity: .medium,
                userMessage: NSLocalizedString("error.database.delete_failed", value: "Failed to delete data. Please try again.", comment: ""),
                technicalMessage: "Database delete operation failed",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .migrationFailed:
            return GenericAppError(
                code: self.rawValue,
                category: .database,
                severity: .critical,
                userMessage: NSLocalizedString("error.database.migration_failed", value: "Database update failed. Please restart the app.", comment: ""),
                technicalMessage: "Database migration failed",
                metadata: metadata,
                recoveryAction: .restart
            )
        case .corruptedData:
            return GenericAppError(
                code: self.rawValue,
                category: .database,
                severity: .high,
                userMessage: NSLocalizedString("error.database.corrupted_data", value: "Data corruption detected. Please contact support.", comment: ""),
                technicalMessage: "Database corruption detected",
                metadata: metadata,
                recoveryAction: .contact
            )
        case .diskFull:
            return GenericAppError(
                code: self.rawValue,
                category: .system,
                severity: .high,
                userMessage: NSLocalizedString("error.system.disk_full", value: "Device storage is full. Please free up space.", comment: ""),
                technicalMessage: "Insufficient disk space",
                metadata: metadata,
                recoveryAction: .ignore
            )
        }
    }
}

// MARK: - App Location Errors
enum AppLocationError: String, CaseIterable {
    case permissionDenied = "LOC_001"
    case serviceDisabled = "LOC_002"
    case locationUnavailable = "LOC_003"
    case accuracyInsufficient = "LOC_004"
    
    func toAppError(metadata: [String: Any]? = nil) -> AppError {
        switch self {
        case .permissionDenied:
            return GenericAppError(
                code: self.rawValue,
                category: .permission,
                severity: .high,
                userMessage: NSLocalizedString("error.location.permission_denied", value: "Location permission is required for time tracking. Please enable it in Settings.", comment: ""),
                technicalMessage: "Location permission denied",
                metadata: metadata,
                recoveryAction: .ignore
            )
        case .serviceDisabled:
            return GenericAppError(
                code: self.rawValue,
                category: .location,
                severity: .medium,
                userMessage: NSLocalizedString("error.location.service_disabled", value: "Location services are disabled. Please enable them in Settings.", comment: ""),
                technicalMessage: "Location services disabled",
                metadata: metadata,
                recoveryAction: .ignore
            )
        case .locationUnavailable:
            return GenericAppError(
                code: self.rawValue,
                category: .location,
                severity: .medium,
                userMessage: NSLocalizedString("error.location.unavailable", value: "Unable to determine location. Please try again.", comment: ""),
                technicalMessage: "Location unavailable",
                metadata: metadata,
                recoveryAction: .retry
            )
        case .accuracyInsufficient:
            return GenericAppError(
                code: self.rawValue,
                category: .location,
                severity: .low,
                userMessage: NSLocalizedString("error.location.accuracy_insufficient", value: "Location accuracy is insufficient. Please try again.", comment: ""),
                technicalMessage: "Location accuracy insufficient",
                metadata: metadata,
                recoveryAction: .retry
            )
        }
    }
}

// MARK: - Error Manager
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private init() {}
    
    func handle(_ error: Error, context: String? = nil) {
        let appError = mapToAppError(error)
        
        // Log the error
        LoggingManager.shared.log(
            level: appError.severity.logLevel,
            category: appError.category.logCategory,
            message: appError.technicalMessage,
            metadata: createErrorMetadata(appError, context: context)
        )
        
        // Report to remote service if needed
        if appError.severity.shouldReportToRemote {
            reportToRemoteService(appError, context: context)
        }
        
        // Show error to user if appropriate
        if shouldShowToUser(appError) {
            DispatchQueue.main.async { [weak self] in
                self?.currentError = appError
                self?.isShowingError = true
            }
        }
    }
    
    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // Map system errors to app errors
        if let urlError = error as? URLError {
            return mapURLError(urlError)
        }
        
        // Default fallback
        return GenericAppError(
            code: "UNKNOWN_001",
            category: .system,
            severity: .medium,
            userMessage: NSLocalizedString("error.unknown", value: "An unexpected error occurred. Please try again.", comment: ""),
            technicalMessage: error.localizedDescription,
            metadata: ["originalError": String(describing: error)],
            recoveryAction: .retry
        )
    }
    
    private func mapURLError(_ urlError: URLError) -> AppError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return AppNetworkError.noConnection.toAppError(metadata: ["urlErrorCode": urlError.code.rawValue])
        case .timedOut:
            return AppNetworkError.timeout.toAppError(metadata: ["urlErrorCode": urlError.code.rawValue])
        case .badURL:
            return AppNetworkError.invalidURL.toAppError(metadata: ["urlErrorCode": urlError.code.rawValue])
        default:
            return AppNetworkError.invalidResponse.toAppError(metadata: ["urlErrorCode": urlError.code.rawValue])
        }
    }
    
    private func createErrorMetadata(_ error: AppError, context: String?) -> [String: Any] {
        var metadata: [String: Any] = [
            "errorCode": error.code,
            "category": error.category.rawValue,
            "severity": error.severity.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "appVersion": AppConfigurationManager.shared.versionNumber,
            "buildNumber": AppConfigurationManager.shared.buildNumber,
            "target": AppConfigurationManager.shared.current.appName
        ]
        
        if let context = context {
            metadata["context"] = context
        }
        
        if let errorMetadata = error.metadata {
            metadata.merge(errorMetadata) { _, new in new }
        }
        
        return metadata
    }
    
    private func shouldShowToUser(_ error: AppError) -> Bool {
        // Don't show low severity errors to users
        guard error.severity != .low else { return false }
        
        // Don't show duplicate errors
        if let currentError = currentError,
           currentError.code == error.code,
           isShowingError {
            return false
        }
        
        return true
    }
    
    private func reportToRemoteService(_ error: AppError, context: String?) {
        // TODO: Implement remote error reporting
        // This could be Firebase Crashlytics, Sentry, or custom service
        logDebug("Reporting error to remote service: \(error.code)", category: .general)
    }
    
    func dismissError() {
        DispatchQueue.main.async { [weak self] in
            self?.currentError = nil
            self?.isShowingError = false
        }
    }
    
    func executeRecoveryAction() {
        guard let error = currentError,
              let recoveryAction = error.recoveryAction else { return }
        
        switch recoveryAction {
        case .retry:
            // Handled by the calling component
            break
        case .refresh:
            // Handled by the calling component
            break
        case .logout:
            // TODO: Implement logout logic
            break
        case .restart:
            // TODO: Implement app restart logic
            break
        case .contact:
            // TODO: Implement contact support logic
            break
        case .ignore:
            break
        case .custom(_, let action):
            action()
        }
        
        dismissError()
    }
}

// MARK: - Result Extension
extension Result {
    func mapError<T: AppError>(_ transform: (Failure) -> T) -> Result<Success, T> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(transform(error))
        }
    }
}

// MARK: - Error Alert Modifier
struct ErrorAlertModifier: ViewModifier {
    @StateObject private var errorManager = ErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: $errorManager.isShowingError,
                presenting: errorManager.currentError
            ) { error in
                Button(error.recoveryAction?.title ?? "OK") {
                    errorManager.executeRecoveryAction()
                }
                
                Button("Cancel", role: .cancel) {
                    errorManager.dismissError()
                }
            } message: { error in
                Text(error.userMessage)
            }
    }
}

extension View {
    func errorAlert() -> some View {
        modifier(ErrorAlertModifier())
    }
}