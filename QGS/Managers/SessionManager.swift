//
//  SessionManager.swift
//  QGS
//
//  Created by Assistant on 2025-08-03.
//
//  Purpose: Manages user session state, including session data storage,
//  session timeouts, and session lifecycle events.
//

import Foundation
import OSLog
import Combine

/// Session data model
struct SessionData {
    let userId: String
    let userName: String
    let userEmail: String
    let employeeId: String
    let sysconfId: Int
    let userType: String
    let sessionStartTime: Date
    
    var isExpired: Bool {
        // Session expires after 24 hours (configurable)
        let expirationInterval: TimeInterval = 24 * 60 * 60
        return Date().timeIntervalSince(sessionStartTime) > expirationInterval
    }
}

/// Manages user session lifecycle and data
final class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "QGS", category: "SessionManager")
    private let defaults = UserDefaults.standard
    
    @Published private(set) var currentSession: SessionData?
    @Published private(set) var isSessionActive: Bool = false
    
    // UserDefaults keys
    private enum Keys {
        static let userId = "userId"
        static let userName = "userName"
        static let userEmail = "userEmail"
        static let employeeId = "employeeId"
        static let sysconfId = "sysconfId"
        static let userType = "userType"
        static let sessionStartTime = "sessionStartTime"
    }
    
    private var sessionTimer: Timer?
    
    private init() {
        loadSession()
        startSessionMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new session from login response
    func createSession(from loginResponse: LoginResponse) {
        guard let user = loginResponse.user else {
            logError("Cannot create session without user data", category: .authentication)
            return
        }
        
        let sessionData = SessionData(
            userId: String(user.id),
            userName: user.name,
            userEmail: user.email,
            employeeId: String(user.employee.id),
            sysconfId: user.sysconf_id,
            userType: user.type,
            sessionStartTime: Date()
        )
        
        saveSession(sessionData)
        currentSession = sessionData
        isSessionActive = true
        
        logInfo("Session created", category: .authentication, metadata: [
            "userId": sessionData.userId,
            "userType": sessionData.userType
        ])
        
        // Post session start notification
        NotificationCenter.default.post(name: .sessionDidStart, object: sessionData)
    }
    
    /// Ends the current session
    func endSession() {
        clearSession()
        currentSession = nil
        isSessionActive = false
        
        logInfo("Session ended", category: .authentication)
        
        // Post session end notification
        NotificationCenter.default.post(name: .sessionDidEnd, object: nil)
    }
    
    /// Gets the current user ID if session is active
    var userId: String? {
        return currentSession?.userId
    }
    
    /// Gets the current employee ID if session is active
    var employeeId: String? {
        return currentSession?.employeeId
    }
    
    /// Gets the current user type if session is active
    var userType: String? {
        return currentSession?.userType
    }
    
    /// Gets the current sysconfId if session is active
    var sysconfId: Int? {
        return currentSession?.sysconfId
    }
    
    /// Checks if the current session is valid
    func isSessionValid() -> Bool {
        guard let session = currentSession else {
            return false
        }
        
        if session.isExpired {
            logWarning("Session expired", category: .authentication)
            endSession()
            return false
        }
        
        return true
    }
    
    /// Refreshes session timeout
    func refreshSession() {
        guard var session = currentSession else { return }
        
        // Update session start time to extend session
        let newSession = SessionData(
            userId: session.userId,
            userName: session.userName,
            userEmail: session.userEmail,
            employeeId: session.employeeId,
            sysconfId: session.sysconfId,
            userType: session.userType,
            sessionStartTime: Date()
        )
        
        saveSession(newSession)
        currentSession = newSession
        
        logInfo("Session refreshed", category: .authentication)
    }
    
    // MARK: - Private Methods
    
    private func loadSession() {
        // Load session data from UserDefaults
        guard let userId = defaults.string(forKey: Keys.userId),
              let userName = defaults.string(forKey: Keys.userName),
              let userEmail = defaults.string(forKey: Keys.userEmail),
              let employeeId = defaults.string(forKey: Keys.employeeId),
              let userType = defaults.string(forKey: Keys.userType) else {
            logInfo("No saved session found", category: .authentication)
            return
        }
        
        let sysconfId = defaults.integer(forKey: Keys.sysconfId)
        let sessionStartTime = defaults.object(forKey: Keys.sessionStartTime) as? Date ?? Date()
        
        let sessionData = SessionData(
            userId: userId,
            userName: userName,
            userEmail: userEmail,
            employeeId: employeeId,
            sysconfId: sysconfId,
            userType: userType,
            sessionStartTime: sessionStartTime
        )
        
        // Check if session is still valid
        if !sessionData.isExpired {
            currentSession = sessionData
            isSessionActive = true
            logInfo("Session restored", category: .authentication, metadata: [
                "userId": userId
            ])
        } else {
            logWarning("Restored session was expired", category: .authentication)
            clearSession()
        }
    }
    
    private func saveSession(_ session: SessionData) {
        defaults.set(session.userId, forKey: Keys.userId)
        defaults.set(session.userName, forKey: Keys.userName)
        defaults.set(session.userEmail, forKey: Keys.userEmail)
        defaults.set(session.employeeId, forKey: Keys.employeeId)
        defaults.set(session.sysconfId, forKey: Keys.sysconfId)
        defaults.set(session.userType, forKey: Keys.userType)
        defaults.set(session.sessionStartTime, forKey: Keys.sessionStartTime)
        defaults.synchronize()
    }
    
    private func clearSession() {
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.userName)
        defaults.removeObject(forKey: Keys.userEmail)
        defaults.removeObject(forKey: Keys.employeeId)
        defaults.removeObject(forKey: Keys.sysconfId)
        defaults.removeObject(forKey: Keys.userType)
        defaults.removeObject(forKey: Keys.sessionStartTime)
        defaults.synchronize()
    }
    
    private func startSessionMonitoring() {
        // Check session validity every 5 minutes
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.isSessionValid()
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let sessionDidStart = Notification.Name("sessionDidStart")
    static let sessionDidEnd = Notification.Name("sessionDidEnd")
    static let sessionWillExpire = Notification.Name("sessionWillExpire")
}