//
//  AuthenticationManager.swift
//  QGS
//
//  Created by Assistant on 2025-08-03.
//
//  Purpose: Handles all authentication-related operations including login,
//  validation, and authentication state management.
//

import Foundation
import Combine
import OSLog

/// Handles authentication operations
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QGS", category: "AuthenticationManager")
    private let tokenManager = TokenManager.shared
    private let errorManager = ErrorManager.shared
    private let networkAdapter = NetworkManagerAdapter.shared
    
    @Published private(set) var loadingState: LoadingState = .idle
    @Published private(set) var isAuthenticated: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Check authentication state on init
        checkAuthenticationState()
    }
    
    // MARK: - Public Methods
    
    /// Performs login with email and password
    func login(email: String, password: String) async throws -> LoginResponse {
        loadingState = .loading
        
        do {
            // Validate credentials
            try validateCredentials(email: email, password: password)
            
            // Perform login
            let loginResponse = try await performLogin(email: email, password: password)
            
            // Save token
            if let token = loginResponse.token {
                try tokenManager.saveToken(token)
            }
            
            isAuthenticated = true
            loadingState = .success(nil)
            
            logInfo("Login successful", category: .authentication, metadata: [
                "userId": String(loginResponse.user?.id ?? 0)
            ])
            
            return loginResponse
            
        } catch {
            loadingState = .failure(error.localizedDescription)
            isAuthenticated = false
            
            logError("Login failed", category: .authentication, metadata: [
                "error": error.localizedDescription
            ])
            
            errorManager.handle(error, context: "Login")
            throw error
        }
    }
    
    /// Logs out the current user
    func logout() {
        do {
            try tokenManager.deleteToken()
            isAuthenticated = false
            loadingState = .idle
            
            logInfo("Logout successful", category: .authentication)
            
            // Post logout notification
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
            
        } catch {
            logError("Logout error", category: .authentication, metadata: [
                "error": error.localizedDescription
            ])
            errorManager.handle(error, context: "Logout")
        }
    }
    
    /// Checks if user is currently authenticated
    func checkAuthenticationState() {
        isAuthenticated = tokenManager.hasValidToken()
        
        logInfo("Authentication state checked", category: .authentication, metadata: [
            "isAuthenticated": String(isAuthenticated)
        ])
    }
    
    /// Validates if the current token is still valid (could make API call)
    func validateToken() async -> Bool {
        guard let token = tokenManager.loadToken() else {
            isAuthenticated = false
            return false
        }
        
        // Here you could make an API call to validate the token
        // For now, just check if it exists and has valid format
        let isValid = tokenManager.isTokenFormatValid(token)
        isAuthenticated = isValid
        
        return isValid
    }
    
    // MARK: - Private Methods
    
    private func performLogin(email: String, password: String) async throws -> LoginResponse {
        try await withCheckedThrowingContinuation { continuation in
            networkAdapter.login(email: email, password: password) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateCredentials(email: String, password: String) throws {
        guard isValidEmail(email) else {
            throw ValidationError.invalidEmail
        }
        
        guard isValidPassword(password) else {
            throw ValidationError.invalidPassword
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, one letter and one number
        let passwordRegEx = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
    static let userDidLogin = Notification.Name("userDidLogin")
}