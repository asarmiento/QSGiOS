//
//  UserDataManager.swift
//  QGS
//
//  Created by Assistant on 2025-08-03.
//
//  Purpose: Manages user data persistence and retrieval using SwiftData.
//  Handles CRUD operations for user data and maintains data integrity.
//

import Foundation
import SwiftData
import OSLog
import Combine

/// Manages user data operations with SwiftData
final class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QGS", category: "UserDataManager")
    
    @Published private(set) var currentUser: UserModel?
    
    private var context: ModelContext?
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configures the manager with a ModelContext
    func configure(with context: ModelContext) {
        self.context = context
        loadCurrentUser()
        
        logInfo("UserDataManager configured with context", category: .database)
    }
    
    // MARK: - Public Methods
    
    /// Saves or updates user data from login response
    func saveUser(from loginResponse: LoginResponse) throws {
        guard let userData = loginResponse.user else {
            throw UserDataError.noUserData
        }
        
        guard let context = context else {
            throw UserDataError.contextNotConfigured
        }
        
        do {
            // Delete any existing users (single user app)
            try deleteAllUsers()
            
            // Create new user
            let newUser = UserModel(
                name: userData.name,
                email: userData.email,
                token: loginResponse.token ?? "",
                employeeId: userData.employee.id,
                sysconf: String(userData.sysconf_id),
                type: userData.type
            )
            
            context.insert(newUser)
            try context.save()
            
            currentUser = newUser
            
            logInfo("User saved successfully", category: .database, metadata: [
                "userId": String(userData.id),
                "email": userData.email
            ])
            
        } catch {
            logError("Failed to save user", category: .database, metadata: [
                "error": error.localizedDescription
            ])
            throw UserDataError.saveFailed(error)
        }
    }
    
    /// Loads the current user from SwiftData
    func loadCurrentUser() {
        guard let context = context else {
            logWarning("Cannot load user - context not configured", category: .database)
            return
        }
        
        do {
            let users = try context.fetch(FetchDescriptor<UserModel>())
            currentUser = users.first
            
            if currentUser != nil {
                logInfo("User loaded successfully", category: .database)
            } else {
                logInfo("No user found in database", category: .database)
            }
            
        } catch {
            logError("Failed to load user", category: .database, metadata: [
                "error": error.localizedDescription
            ])
        }
    }
    
    /// Updates specific user fields
    func updateUser(name: String? = nil, email: String? = nil) throws {
        guard let context = context else {
            throw UserDataError.contextNotConfigured
        }
        
        guard let user = currentUser else {
            throw UserDataError.userNotFound
        }
        
        // Update fields if provided
        if let name = name {
            user.name = name
        }
        
        if let email = email {
            user.email = email
        }
        
        do {
            try context.save()
            logInfo("User updated successfully", category: .database)
        } catch {
            logError("Failed to update user", category: .database, metadata: [
                "error": error.localizedDescription
            ])
            throw UserDataError.updateFailed(error)
        }
    }
    
    /// Deletes the current user
    func deleteCurrentUser() throws {
        guard let context = context else {
            throw UserDataError.contextNotConfigured
        }
        
        guard let user = currentUser else {
            throw UserDataError.userNotFound
        }
        
        do {
            context.delete(user)
            try context.save()
            currentUser = nil
            
            logInfo("User deleted successfully", category: .database)
        } catch {
            logError("Failed to delete user", category: .database, metadata: [
                "error": error.localizedDescription
            ])
            throw UserDataError.deleteFailed(error)
        }
    }
    
    /// Checks if a user exists in the database
    func userExists() -> Bool {
        guard let context = context else {
            logWarning("Cannot check user existence - context not configured", category: .database)
            return false
        }
        
        do {
            let userCount = try context.fetchCount(FetchDescriptor<UserModel>())
            return userCount > 0
        } catch {
            logError("Failed to check user existence", category: .database, metadata: [
                "error": error.localizedDescription
            ])
            return false
        }
    }
    
    /// Refreshes user data from database
    func refreshUser() {
        loadCurrentUser()
    }
    
    // MARK: - Private Methods
    
    private func deleteAllUsers() throws {
        guard let context = context else {
            throw UserDataError.contextNotConfigured
        }
        
        let users = try context.fetch(FetchDescriptor<UserModel>())
        for user in users {
            context.delete(user)
        }
    }
}

// MARK: - User Data Errors

enum UserDataError: LocalizedError {
    case contextNotConfigured
    case noUserData
    case userNotFound
    case saveFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .contextNotConfigured:
            return "UserDataManager context not configured"
        case .noUserData:
            return "No user data provided"
        case .userNotFound:
            return "User not found in database"
        case .saveFailed(let error):
            return "Failed to save user: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update user: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete user: \(error.localizedDescription)"
        }
    }
}