//
//  TokenManager.swift
//  QGS
//
//  Created by Assistant on 2025-08-03.
//
//  Purpose: Manages all token-related operations including storage, retrieval,
//  migration, and validation. Provides a single point of responsibility for
//  token management across the application.
//

import Foundation
import OSLog

/// Manages authentication token operations
final class TokenManager {
    static let shared = TokenManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QGS", category: "TokenManager")
    private let securityManager = SecurityManager.shared
    private let errorManager = ErrorManager.shared
    
    private let tokenKey = "authToken"
    private let migrationKey = "keychain_migration_attempted"
    
    private init() {
        // Execute migration on initialization if needed
        performMigrationIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Saves authentication token securely
    func saveToken(_ token: String) throws {
        guard !token.isEmpty else {
            throw TokenError.emptyToken
        }
        
        do {
            try securityManager.saveAuthToken(token)
            logInfo("Token saved successfully", category: .security, metadata: [
                "tokenPrefix": String(token.prefix(10))
            ])
        } catch {
            logError("Failed to save token", category: .security, metadata: [
                "error": error.localizedDescription
            ])
            errorManager.handle(error, context: "Token storage")
            throw TokenError.saveFailed(error)
        }
    }
    
    /// Loads authentication token from secure storage
    func loadToken() -> String? {
        do {
            let token = try securityManager.loadAuthToken()
            if !token.isEmpty {
                return token
            }
            return nil
        } catch {
            logWarning("Failed to load token from keychain", category: .security, metadata: [
                "error": error.localizedDescription
            ])
            return nil
        }
    }
    
    /// Deletes authentication token from secure storage
    func deleteToken() throws {
        do {
            try securityManager.deleteAuthToken()
            logInfo("Token deleted successfully", category: .security)
        } catch {
            logError("Failed to delete token", category: .security, metadata: [
                "error": error.localizedDescription
            ])
            throw TokenError.deleteFailed(error)
        }
    }
    
    /// Validates if a token exists and is not empty
    func hasValidToken() -> Bool {
        guard let token = loadToken() else {
            return false
        }
        return !token.isEmpty
    }
    
    /// Validates token format (basic validation)
    func isTokenFormatValid(_ token: String) -> Bool {
        // Basic validation - can be expanded based on token format requirements
        return !token.isEmpty && token.count > 20
    }
    
    // MARK: - Migration
    
    /// Performs token migration from UserDefaults to Keychain if needed
    private func performMigrationIfNeeded() {
        let defaults = UserDefaults.standard
        
        // Check if migration was already attempted
        if defaults.bool(forKey: migrationKey) {
            return
        }
        
        logInfo("Starting token migration", category: .security)
        
        // Check for token in UserDefaults
        if let legacyToken = defaults.string(forKey: tokenKey), !legacyToken.isEmpty {
            do {
                // Save to secure storage
                try saveToken(legacyToken)
                
                // Remove from UserDefaults after successful migration
                defaults.removeObject(forKey: tokenKey)
                
                logInfo("Token migration completed successfully", category: .security)
            } catch {
                logError("Token migration failed", category: .security, metadata: [
                    "error": error.localizedDescription
                ])
            }
        }
        
        // Mark migration as attempted
        defaults.set(true, forKey: migrationKey)
        defaults.synchronize()
    }
    
    /// Force token migration (useful for testing or manual trigger)
    func forceMigration() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: migrationKey)
        defaults.synchronize()
        performMigrationIfNeeded()
    }
}

// MARK: - Token Errors

enum TokenError: LocalizedError {
    case emptyToken
    case saveFailed(Error)
    case loadFailed(Error)
    case deleteFailed(Error)
    case invalidFormat
    
    var errorDescription: String? {
        switch self {
        case .emptyToken:
            return "Token cannot be empty"
        case .saveFailed(let error):
            return "Failed to save token: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load token: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete token: \(error.localizedDescription)"
        case .invalidFormat:
            return "Invalid token format"
        }
    }
}