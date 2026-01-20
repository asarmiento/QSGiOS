//
//  UserManager.swift
//  QGS
//
//  Created by Anwar Sarmiento on 12/8/24.
//  Refactored by Assistant on 2025-08-03.
//
//  Purpose: Facade class that orchestrates user-related operations
//  by delegating to specialized managers. Maintains backward compatibility
//  while providing a cleaner architecture.
//

import Foundation
import SwiftData
import OSLog
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QGS", category: "UserManager")
    
    // Specialized managers
    private let tokenManager = TokenManager.shared
    private let authManager = AuthenticationManager.shared
    private let sessionManager = SessionManager.shared
    private let userDataManager = UserDataManager.shared
    private let errorManager = ErrorManager.shared
    
    @Published private(set) var loadingState: LoadingState = .idle
    
    // Legacy properties maintained for compatibility
    private var context: ModelContext?
    
    // Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBindings()
        
        // Check if session exists on init
        if sessionManager.isSessionActive {
            logInfo("Active session found on UserManager init", category: .authentication)
        }
    }
    
    // MARK: - Backward Compatible Properties
    
    var getAuthToken: String? {
        return tokenManager.loadToken()
    }
    
    var getUserType: String? {
        return sessionManager.userType
    }
    
    var getEmployeeId: String? {
        return sessionManager.employeeId
    }
    
    // MARK: - Configuration
    
    func configure(with context: ModelContext) {
        self.context = context
        userDataManager.configure(with: context)
        logInfo("UserManager configured with context", category: .general)
    }
    
    // MARK: - User Operations
    
    func getUser() -> UserModel? {
        return userDataManager.currentUser
    }
    
    func userExists(completion: @escaping (Bool) -> Void) {
        completion(userDataManager.userExists())
    }
    
    func refreshUser() {
        userDataManager.refreshUser()
    }
    
    // MARK: - Authentication Operations
    
    func saveUser(from response: LoginResponse) {
        // Create session FIRST - this is critical for app functionality
        // Session creation doesn't depend on SwiftData and shouldn't be blocked by it
        sessionManager.createSession(from: response)

        logInfo("Session creation attempted", category: .authentication, metadata: [
            "sessionActive": sessionManager.isSessionActive,
            "hasEmployeeId": sessionManager.employeeId != nil
        ])

        do {
            // Save token
            if let token = response.token {
                try tokenManager.saveToken(token)
                logInfo("Token saved successfully", category: .authentication)
            } else {
                logWarning("No token in login response", category: .authentication)
            }

            // Save user data to SwiftData (optional, for local persistence)
            try userDataManager.saveUser(from: response)

            logInfo("User saved successfully through facade", category: .authentication)
        } catch {
            // Log the error but don't block - session is already created
            logError("Failed to save user data to SwiftData (session still active)", category: .authentication, metadata: [
                "error": error.localizedDescription
            ])
            // Don't call errorManager.handle() here as it would show an error to user
            // even though login was successful
        }
    }
    
    func validateAndSaveUser(_ userData: [String: Any]) async throws {
        loadingState = .loading
        
        guard let email = userData["email"] as? String,
              let password = userData["password"] as? String else {
            loadingState = .failure("Invalid input data")
            throw ValidationError.invalidInput("email or password")
        }
        
        do {
            // Delegate to authentication manager
            let loginResponse = try await authManager.login(email: email, password: password)
            
            // Save user data and create session
            saveUser(from: loginResponse)
            
            loadingState = .success(nil)
        } catch {
            loadingState = .failure(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Session Operations
    
    func logout() {
        // End session
        sessionManager.endSession()
        
        // Clear authentication
        authManager.logout()
        
        // Delete user data
        do {
            try userDataManager.deleteCurrentUser()
        } catch {
            logError("Error deleting user data during logout", category: .authentication, metadata: [
                "error": error.localizedDescription
            ])
        }
        
        logInfo("User logged out successfully", category: .authentication)
    }
    
    // MARK: - Migration Support
    
    func runMigrations() {
        // Token migration is now handled automatically by TokenManager
        logInfo("Migrations delegated to specialized managers", category: .security)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind authentication manager state to local state
        authManager.$loadingState
            .assign(to: &$loadingState)
    }
}

enum ValidationError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case invalidInput(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return NSLocalizedString("INVALID_EMAIL", comment: "")
        case .invalidPassword:
            return NSLocalizedString("INVALID_PASSWORD", comment: "")
        case .invalidInput(let field):
            return String(format: NSLocalizedString("INVALID_FIELD", comment: ""), field)
        }
    }
}
