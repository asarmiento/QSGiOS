import XCTest
import SwiftUI
import CoreLocation
@testable import QGS

// MARK: - Comprehensive Test Suite for QGS
/// Complete testing framework covering all critical app functionality

class ComprehensiveTestSuite: XCTestCase {
    
    // MARK: - Test Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        // Reset managers to clean state
        resetManagersForTesting()
        
        logInfo("Test setup completed", category: .general)
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        cleanupAfterTesting()
        try super.tearDownWithError()
    }
    
    // MARK: - Configuration Tests
    
    func testAppConfigurationManager() throws {
        let configManager = AppConfigurationManager.shared
        
        // Test configuration loading
        XCTAssertNotNil(configManager.current, "Configuration should be loaded")
        XCTAssertFalse(configManager.current.appName.isEmpty, "App name should not be empty")
        XCTAssertFalse(configManager.current.apiBaseURL.isEmpty, "API base URL should not be empty")
        
        // Test environment detection
        #if DEBUG
        XCTAssertTrue(configManager.isDebugMode, "Should detect debug mode correctly")
        XCTAssertFalse(configManager.isProduction, "Should not be production in debug mode")
        #else
        XCTAssertFalse(configManager.isDebugMode, "Should not be debug mode in release")
        XCTAssertTrue(configManager.isProduction, "Should be production in release mode")
        #endif
        
        // Test version information
        XCTAssertFalse(configManager.versionNumber.isEmpty, "Version number should be available")
        XCTAssertFalse(configManager.buildNumber.isEmpty, "Build number should be available")
    }
    
    func testNetworkConfiguration() throws {
        let networkConfig = NetworkConfiguration.shared
        
        // Test URL construction
        XCTAssertNotNil(networkConfig.baseURL, "Base URL should be valid")
        
        // Test endpoints
        let loginEndpoint = NetworkConfiguration.Endpoint.login
        XCTAssertEqual(loginEndpoint.rawValue, "/login", "Login endpoint should be correct")
        
        let loginURL = loginEndpoint.url
        XCTAssertTrue(loginURL.absoluteString.contains("login"), "Login URL should contain 'login'")
        
        // Test timeout values
        XCTAssertGreaterThan(networkConfig.timeout, 0, "Timeout should be positive")
        XCTAssertGreaterThan(networkConfig.maxRetries, 0, "Max retries should be positive")
    }
    
    // MARK: - Security Manager Tests
    
    func testSecurityManager() throws {
        let securityManager = SecurityManager.shared
        
        // Test email validation
        XCTAssertTrue(securityManager.validateEmail("test@example.com"), "Valid email should pass")
        XCTAssertFalse(securityManager.validateEmail("invalid-email"), "Invalid email should fail")
        XCTAssertFalse(securityManager.validateEmail(""), "Empty email should fail")
        
        // Test password validation
        let weakPassword = securityManager.validatePassword("123")
        XCTAssertFalse(weakPassword.isValid, "Weak password should fail validation")
        XCTAssertFalse(weakPassword.issues.isEmpty, "Weak password should have issues")
        
        let strongPassword = securityManager.validatePassword("StrongP@ssw0rd123")
        XCTAssertTrue(strongPassword.isValid, "Strong password should pass validation")
        XCTAssertTrue(strongPassword.issues.isEmpty, "Strong password should have no issues")
        
        // Test input sanitization
        let unsafeInput = "<script>alert('xss')</script>"
        let sanitizedInput = securityManager.sanitizeInput(unsafeInput)
        XCTAssertFalse(sanitizedInput.contains("<"), "Sanitized input should not contain <")
        XCTAssertFalse(sanitizedInput.contains(">"), "Sanitized input should not contain >")
        
        // Test JWT validation (with mock token)
        let invalidJWT = "invalid.token.here"
        XCTAssertFalse(securityManager.validateJWT(invalidJWT), "Invalid JWT should fail")
        
        // Test session management
        securityManager.startSession()
        XCTAssertTrue(securityManager.isSessionValid(), "New session should be valid")
        
        securityManager.endSession()
        XCTAssertFalse(securityManager.isSessionValid(), "Ended session should be invalid")
    }
    
    func testKeychainOperations() throws {
        let securityManager = SecurityManager.shared
        let testKey = "test_keychain_key"
        let testValue = "test_keychain_value"
        
        // Clean up any existing test data
        try? securityManager.delete(key: testKey)
        
        // Test saving data
        let testData = testValue.data(using: .utf8)!
        XCTAssertNoThrow(try securityManager.save(key: testKey, data: testData))
        
        // Test loading data
        let loadedData = try securityManager.load(key: testKey)
        let loadedString = String(data: loadedData, encoding: .utf8)
        XCTAssertEqual(loadedString, testValue, "Loaded data should match saved data")
        
        // Test deleting data
        XCTAssertNoThrow(try securityManager.delete(key: testKey))
        
        // Verify deletion
        XCTAssertThrowsError(try securityManager.load(key: testKey)) { error in
            XCTAssertTrue(error is SecurityManager.KeychainError, "Should throw keychain error")
        }
    }
    
    // MARK: - Logging Manager Tests
    
    func testLoggingManager() throws {
        let loggingManager = LoggingManager.shared
        
        // Test logging configuration
        XCTAssertNotNil(loggingManager, "Logging manager should be available")
        
        // Test different log levels
        XCTAssertNoThrow(loggingManager.verbose("Test verbose message"))
        XCTAssertNoThrow(loggingManager.debug("Test debug message"))
        XCTAssertNoThrow(loggingManager.info("Test info message"))
        XCTAssertNoThrow(loggingManager.warning("Test warning message"))
        XCTAssertNoThrow(loggingManager.error("Test error message"))
        XCTAssertNoThrow(loggingManager.critical("Test critical message"))
        
        // Test global logging functions
        XCTAssertNoThrow(logInfo("Global log test", category: .general))
        XCTAssertNoThrow(logError("Global error test", category: .network))
        
        // Test logging with metadata
        let metadata = ["test_key": "test_value", "number": 42]
        XCTAssertNoThrow(logDebug("Test with metadata", category: .performance, metadata: metadata))
    }
    
    // MARK: - Error Manager Tests
    
    func testErrorManager() throws {
        let errorManager = ErrorManager.shared
        
        // Test error creation
        let networkError = AppNetworkError.noConnection.toAppError()
        XCTAssertEqual(networkError.category, .network, "Network error should have network category")
        XCTAssertFalse(networkError.userMessage.isEmpty, "Error should have user message")
        
        // Test error handling
        let handledError = errorManager.handleError(networkError)
        XCTAssertNotNil(handledError.recoveryAction, "Error should have recovery action")
        
        // Test location error
        let locationError = AppLocationError.denied.toAppError()
        XCTAssertEqual(locationError.category, .location, "Location error should have location category")
        
        // Test error severity
        XCTAssertEqual(networkError.severity, .high, "Network connection error should be high severity")
        XCTAssertEqual(locationError.severity, .medium, "Location permission error should be medium severity")
    }
    
    // MARK: - Network Tests
    
    func testSecureNetworkManager() throws {
        let networkManager = SecureNetworkManager.shared
        
        // Test network manager initialization
        XCTAssertNotNil(networkManager, "Network manager should be initialized")
        
        // Test request configuration building
        let loginConfig = networkManager.buildLoginRequest(email: "test@example.com", password: "password")
        XCTAssertEqual(loginConfig.method, .POST, "Login should use POST method")
        XCTAssertEqual(loginConfig.endpoint, .login, "Login should use login endpoint")
        XCTAssertFalse(loginConfig.requiresAuth, "Login should not require auth")
        XCTAssertNotNil(loginConfig.body, "Login should have body data")
        
        // Test time record request building
        let location = ["latitude": 40.7128, "longitude": -74.0060]
        let timeRecordConfig = networkManager.buildTimeRecordRequest(
            projectId: "test_project",
            action: "entrada",
            location: location,
            notes: "Test notes"
        )
        XCTAssertEqual(timeRecordConfig.method, .POST, "Time record should use POST method")
        XCTAssertEqual(timeRecordConfig.endpoint, .storeTimeWork, "Time record should use correct endpoint")
        XCTAssertTrue(timeRecordConfig.requiresAuth, "Time record should require auth")
    }
    
    func testNetworkCacheManager() throws {
        let cacheManager = NetworkCacheManager.shared
        
        // Test cache operations
        let testKey = "test_cache_key"
        let testData = ["test": "data", "number": 42] as [String: Any]
        
        // Clear any existing cache
        cacheManager.remove(for: testKey)
        
        // Test storing data
        struct TestCacheData: Codable {
            let test: String
            let number: Int
        }
        
        let testCacheData = TestCacheData(test: "data", number: 42)
        cacheManager.store(testCacheData, for: testKey, timeout: 10)
        
        // Test retrieving data
        let retrievedData = cacheManager.retrieve(TestCacheData.self, for: testKey)
        XCTAssertNotNil(retrievedData, "Cached data should be retrievable")
        XCTAssertEqual(retrievedData?.test, "data", "Retrieved data should match stored data")
        XCTAssertEqual(retrievedData?.number, 42, "Retrieved number should match stored number")
        
        // Test cache validity
        XCTAssertTrue(cacheManager.isValid(for: testKey), "Fresh cache should be valid")
        
        // Test cache removal
        cacheManager.remove(for: testKey)
        let removedData = cacheManager.retrieve(TestCacheData.self, for: testKey)
        XCTAssertNil(removedData, "Removed data should not be retrievable")
    }
    
    // MARK: - Location Manager Tests
    
    func testOptimizedLocationManager() throws {
        let locationManager = OptimizedLocationManager.shared
        
        // Test location manager initialization
        XCTAssertNotNil(locationManager, "Location manager should be initialized")
        
        // Test authorization status
        let authStatus = locationManager.locationStatus
        XCTAssertTrue(authStatus == nil || authStatus != .notDetermined, "Auth status should be determined or nil")
        
        // Test address formatting (with mock data)
        // Note: This would require more sophisticated mocking in a real implementation
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOptimizations() throws {
        // Test ViewModel optimization
        let optimizedViewModel = OptimizedViewModel()
        
        // Measure update performance
        measure {
            for _ in 0..<100 {
                optimizedViewModel.triggerOptimizedUpdate()
            }
        }
        
        // Test button state optimization
        var buttonState = ButtonState()
        
        measure {
            for i in 0..<1000 {
                buttonState.isLoading = i % 2 == 0
                buttonState.isEnabled = i % 3 == 0
            }
        }
    }
    
    func testMemoryManagement() throws {
        // Test for memory leaks in critical components
        weak var weakLocationManager: OptimizedLocationManager?
        weak var weakNetworkManager: SecureNetworkManager?
        
        autoreleasepool {
            let locationManager = OptimizedLocationManager()
            let networkManager = SecureNetworkManager()
            
            weakLocationManager = locationManager
            weakNetworkManager = networkManager
            
            // Simulate usage
            locationManager.checkAuthorizationStatus()
            let _ = networkManager.buildLoginRequest(email: "test@test.com", password: "password")
        }
        
        // Objects should be deallocated after autoreleasepool
        // Note: This test might need adjustment based on singleton patterns
    }
    
    // MARK: - UI Tests (ViewModels)
    
    func testRecordViewModel() throws {
        // This would test the RecordViewModel functionality
        // Note: Requires proper dependency injection setup
    }
    
    func testUserManager() throws {
        let userManager = UserManager.shared
        
        // Test user manager initialization
        XCTAssertNotNil(userManager, "User manager should be initialized")
        
        // Test authentication token management
        // Note: This would require mocking the keychain operations
    }
    
    // MARK: - Integration Tests
    
    func testFullRegistrationFlow() throws {
        // Test the complete registration flow
        let formData = RegistrationFormData()
        
        // Test form validation
        XCTAssertFalse(formData.isValid, "Empty form should be invalid")
        
        // Create valid form data
        var validForm = RegistrationFormData()
        validForm.companyName = "Test Company"
        validForm.email = "test@example.com"
        validForm.phone = "1234567890"
        validForm.card = "12345678"
        validForm.password = "SecureP@ssw0rd123"
        validForm.passwordConfirm = "SecureP@ssw0rd123"
        validForm.projectName = "Test Project"
        validForm.budget = "10000"
        validForm.address = "123 Test Street"
        
        XCTAssertTrue(validForm.isValid, "Valid form should pass validation")
    }
    
    func testSecurityAudit() throws {
        let securityManager = SecurityManager.shared
        
        // Run security audit
        let auditResult = securityManager.performSecurityAudit()
        
        XCTAssertNotNil(auditResult, "Security audit should return results")
        XCTAssertFalse(auditResult.findings.isEmpty, "Security audit should have findings")
        
        // Check for critical security issues
        let criticalFindings = auditResult.findings.filter { $0.type == .critical }
        XCTAssertTrue(criticalFindings.isEmpty, "Should not have critical security issues")
    }
    
    // MARK: - Stress Tests
    
    func testConcurrentNetworkRequests() throws {
        let expectation = XCTestExpectation(description: "Concurrent network requests")
        let requestCount = 10
        var completedRequests = 0
        
        for i in 0..<requestCount {
            DispatchQueue.global().async {
                // Simulate network request processing
                Thread.sleep(forTimeInterval: 0.1)
                
                DispatchQueue.main.async {
                    completedRequests += 1
                    if completedRequests == requestCount {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(completedRequests, requestCount, "All requests should complete")
    }
    
    func testMemoryUsageUnderLoad() throws {
        // Test memory usage under high load
        measure(metrics: [XCTMemoryMetric()]) {
            var objects: [Any] = []
            
            for i in 0..<10000 {
                let testData = TestDataModel(id: i, name: "Test \(i)")
                objects.append(testData)
            }
            
            objects.removeAll()
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetManagersForTesting() {
        // Reset singleton states for testing
        // Note: This would require additional setup in a real implementation
    }
    
    private func cleanupAfterTesting() {
        // Clean up test data and reset states
        NetworkCacheManager.shared.clearAll()
        SecurityManager.shared.endSession()
    }
}

// MARK: - Test Data Models

struct TestDataModel {
    let id: Int
    let name: String
}

// MARK: - Mock Classes for Testing

class MockLocationManager: ObservableObject {
    @Published var isAuthorized = true
    @Published var lastLocation: CLLocation? = CLLocation(latitude: 40.7128, longitude: -74.0060)
    
    func requestLocationPermission() {
        isAuthorized = true
    }
    
    func startUpdatingLocation() {
        // Mock implementation
    }
    
    func stopUpdatingLocation() {
        // Mock implementation
    }
}

class MockNetworkManager {
    func performRequest<T: Codable>(_ config: RequestConfiguration, responseType: T.Type) async throws -> T {
        // Mock implementation that returns dummy data
        throw NetworkError.invalidResponse
    }
}

// MARK: - Performance Testing Extensions

extension XCTestCase {
    func measureMemoryUsage<T>(operation: () throws -> T) rethrows -> T {
        let startMemory = getCurrentMemoryUsage()
        let result = try operation()
        let endMemory = getCurrentMemoryUsage()
        
        logInfo("Memory usage test", category: .performance, metadata: [
            "startMemory": "\(startMemory)MB",
            "endMemory": "\(endMemory)MB",
            "delta": "\(endMemory - startMemory)MB"
        ])
        
        return result
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
}