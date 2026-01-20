import Foundation
import SwiftUI

// Simple test to verify our new classes compile
struct CompilationTest {
    func testNewClasses() {
        // Test AppConfiguration
        let config = AppConfigurationManager.shared
        print("App name: \(config.current.appName)")
        
        // Test Logging
        logInfo("Test message", category: .general)
        
        // Test Security
        let security = SecurityManager.shared
        let isAvailable = security.isBiometricAvailable()
        print("Biometric available: \(isAvailable)")
        
        // Test Error Manager
        let errorManager = ErrorManager.shared
        print("Error manager ready")
        
        // Test Network
        let networkManager = SecureNetworkManager.shared
        print("Network manager connected: \(networkManager.isConnected)")
        
        // Test Network Adapter
        let adapter = NetworkManagerAdapter.shared
        print("Network adapter ready")
        
        // Test UserManager
        let userManager = UserManager.shared
        print("User manager ready")
    }
}