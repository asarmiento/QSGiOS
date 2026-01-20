import Foundation
import Security
import CryptoKit
import LocalAuthentication

// MARK: - Security Manager
class SecurityManager {
    static let shared = SecurityManager()
    
    private let keychainService = "com.qgs.keychain"
    private let biometricContext = LAContext()
    
    private init() {}
    
    // MARK: - Keychain Operations
    enum KeychainError: Error {
        case invalidData
        case itemNotFound
        case duplicateItem
        case unexpectedError(OSStatus)
    }
    
    func save(key: String, data: Data, requiresBiometric: Bool = false) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: requiresBiometric ? kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            try update(key: key, data: data, requiresBiometric: requiresBiometric)
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
    
    func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidData
            }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            throw KeychainError.unexpectedError(status)
        }
    }
    
    private func update(key: String, data: Data, requiresBiometric: Bool) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let updateData: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: requiresBiometric ? kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemUpdate(query as CFDictionary, updateData as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedError(status)
        }
    }
    
    // MARK: - Token Management
    private let tokenKey = "auth_token"
    private let refreshTokenKey = "refresh_token"
    
    func saveAuthToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(key: tokenKey, data: data, requiresBiometric: false)
        
        logInfo("Auth token saved to keychain", category: .security)
    }
    
    func loadAuthToken() throws -> String {
        let data = try load(key: tokenKey)
        guard let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return token
    }
    
    func deleteAuthToken() throws {
        try delete(key: tokenKey)
        logInfo("Auth token deleted from keychain", category: .security)
    }
    
    func saveRefreshToken(_ token: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(key: refreshTokenKey, data: data, requiresBiometric: false)
    }
    
    func loadRefreshToken() throws -> String {
        let data = try load(key: refreshTokenKey)
        guard let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return token
    }
    
    func deleteRefreshToken() throws {
        try delete(key: refreshTokenKey)
    }
    
    // MARK: - Biometric Authentication
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        let available = biometricContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        if let error = error {
            logWarning("Biometric authentication not available: \(error.localizedDescription)", category: .security)
        }
        
        return available
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        
        let reason = NSLocalizedString("security.biometric.reason", value: "Authenticate to access your account", comment: "")
        
        do {
            let result = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            logInfo("Biometric authentication successful", category: .security)
            return result
        } catch {
            logWarning("Biometric authentication failed: \(error.localizedDescription)", category: .security)
            throw error
        }
    }
    
    // MARK: - Data Encryption
    func encryptData(_ data: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decryptData(_ encryptedData: Data, key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func generateEncryptionKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    // MARK: - JWT Token Validation
    func validateJWT(_ token: String) -> Bool {
        let components = token.split(separator: ".")
        guard components.count == 3 else {
            logWarning("Invalid JWT format", category: .security)
            return false
        }
        
        // Decode payload
        guard let payloadData = Data(base64Encoded: String(components[1])),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval else {
            logWarning("Invalid JWT payload", category: .security)
            return false
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        let isValid = expirationDate > Date()
        
        if !isValid {
            logWarning("JWT token expired", category: .security)
        }
        
        return isValid
    }
    
    // MARK: - Input Validation
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> PasswordValidationResult {
        var issues: [String] = []
        
        if password.count < 8 {
            issues.append(NSLocalizedString("password.error.length", value: "Password must be at least 8 characters", comment: ""))
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            issues.append(NSLocalizedString("password.error.uppercase", value: "Password must contain at least one uppercase letter", comment: ""))
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            issues.append(NSLocalizedString("password.error.lowercase", value: "Password must contain at least one lowercase letter", comment: ""))
        }
        
        if !password.contains(where: { $0.isNumber }) {
            issues.append(NSLocalizedString("password.error.number", value: "Password must contain at least one number", comment: ""))
        }
        
        let specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        if !password.contains(where: { specialCharacters.contains($0) }) {
            issues.append(NSLocalizedString("password.error.special", value: "Password must contain at least one special character", comment: ""))
        }
        
        return PasswordValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    func sanitizeInput(_ input: String) -> String {
        // Remove potential XSS characters
        var sanitized = input
        let dangerousChars = ["<", ">", "&", "\"", "'", "/", "\\"]
        
        for char in dangerousChars {
            sanitized = sanitized.replacingOccurrences(of: char, with: "")
        }
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Certificate Pinning
    func validateCertificate(_ trust: SecTrust, for host: String) -> Bool {
        // Get pinned certificates for the host
        let pinnedCertificates = NetworkConfiguration.shared.pinnedCertificates
        
        guard !pinnedCertificates.isEmpty else {
            logWarning("No pinned certificates configured for host: \(host)", category: .security)
            return true // Allow connection if no pinning configured
        }
        
        // Get server certificates
        let serverCertCount = SecTrustGetCertificateCount(trust)
        
        for i in 0..<serverCertCount {
            guard let serverCert = SecTrustGetCertificateAtIndex(trust, i) else { continue }
            
            let serverCertData = SecCertificateCopyData(serverCert)
            let serverCertHash = SHA256.hash(data: serverCertData as Data)
            let serverCertHashString = serverCertHash.compactMap { String(format: "%02x", $0) }.joined()
            
            if pinnedCertificates.contains(serverCertHashString) {
                logInfo("Certificate pinning validation successful for host: \(host)", category: .security)
                return true
            }
        }
        
        logError("Certificate pinning validation failed for host: \(host)", category: .security)
        return false
    }
    
    // MARK: - Session Management
    private let sessionTimeoutKey = "session_timeout"
    private let maxSessionDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    func startSession() {
        let sessionTimeout = Date().addingTimeInterval(maxSessionDuration)
        UserDefaults.standard.set(sessionTimeout, forKey: sessionTimeoutKey)
        
        logInfo("Session started with timeout: \(sessionTimeout)", category: .security)
    }
    
    func isSessionValid() -> Bool {
        guard let sessionTimeout = UserDefaults.standard.object(forKey: sessionTimeoutKey) as? Date else {
            return false
        }
        
        let isValid = sessionTimeout > Date()
        
        if !isValid {
            logInfo("Session expired", category: .security)
        }
        
        return isValid
    }
    
    func extendSession() {
        guard isSessionValid() else { return }
        
        let newTimeout = Date().addingTimeInterval(maxSessionDuration)
        UserDefaults.standard.set(newTimeout, forKey: sessionTimeoutKey)
        
        logInfo("Session extended to: \(newTimeout)", category: .security)
    }
    
    func endSession() {
        UserDefaults.standard.removeObject(forKey: sessionTimeoutKey)
        
        // Clean up tokens
        try? deleteAuthToken()
        try? deleteRefreshToken()
        
        logInfo("Session ended", category: .security)
    }
    
    // MARK: - Security Audit
    func performSecurityAudit() -> SecurityAuditResult {
        var findings: [SecurityFinding] = []
        
        // Check for stored sensitive data
        if let _ = try? loadAuthToken() {
            findings.append(SecurityFinding(
                type: .info,
                message: "Auth token found in keychain",
                recommendation: "Ensure token is properly secured"
            ))
        }
        
        // Check session validity
        if !isSessionValid() {
            findings.append(SecurityFinding(
                type: .warning,
                message: "Invalid session detected",
                recommendation: "User should be logged out"
            ))
        }
        
        // Check biometric availability
        if !isBiometricAvailable() {
            findings.append(SecurityFinding(
                type: .info,
                message: "Biometric authentication not available",
                recommendation: "Consider implementing alternative security measures"
            ))
        }
        
        // Check certificate pinning configuration
        if NetworkConfiguration.shared.pinnedCertificates.isEmpty {
            findings.append(SecurityFinding(
                type: .warning,
                message: "Certificate pinning not configured",
                recommendation: "Implement certificate pinning for production"
            ))
        }
        
        return SecurityAuditResult(findings: findings)
    }
}

// MARK: - Supporting Types
struct PasswordValidationResult {
    let isValid: Bool
    let issues: [String]
}

struct SecurityFinding {
    enum SecurityFindingType {
        case info
        case warning
        case error
        case critical
    }
    
    let type: SecurityFindingType
    let message: String
    let recommendation: String
}

struct SecurityAuditResult {
    let findings: [SecurityFinding]
    let timestamp: Date = Date()
    
    var hasWarnings: Bool {
        findings.contains { $0.type == .warning }
    }
    
    var hasErrors: Bool {
        findings.contains { $0.type == .error }
    }
    
    var hasCritical: Bool {
        findings.contains { $0.type == .critical }
    }
}

// MARK: - Security Extensions
extension SecurityManager {
    func hashPassword(_ password: String, salt: String) -> String {
        let saltedPassword = password + salt
        let hash = SHA256.hash(data: Data(saltedPassword.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func generateSalt() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<16).map { _ in letters.randomElement()! })
    }
    
    func generateSecureRandomString(length: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
}