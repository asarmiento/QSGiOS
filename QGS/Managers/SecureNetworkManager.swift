import Foundation
import Network
import UIKit

// MARK: - Secure Network Manager
class SecureNetworkManager: NSObject, ObservableObject {
    static let shared = SecureNetworkManager()
    
    private var session: URLSession
    private let securityManager = SecurityManager.shared
    private let networkConfig = NetworkConfiguration.shared
    
    @Published var isConnected = false
    
    override init() {
        // Configure secure session
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = networkConfig.timeout
        configuration.timeoutIntervalForResource = networkConfig.timeout * 2
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        // Security headers
        configuration.httpAdditionalHeaders = networkConfig.defaultHeaders
        
        // Initialize temporarily
        self.session = URLSession(configuration: configuration)
        
        super.init()
        
        // Create session with custom delegate for certificate pinning
        self.session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
        
        // Monitor network connectivity
        setupNetworkMonitoring()
        
        logInfo("SecureNetworkManager initialized", category: .network)
    }
    
    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        
        monitor.start(queue: queue)
    }
    
    // MARK: - Secure Request Methods
    func performRequest<T: Codable>(
        _ config: RequestConfiguration,
        responseType: T.Type
    ) async throws -> T {
        guard isConnected else {
            throw AppNetworkError.noConnection.toAppError()
        }
        
        let request = try buildSecureRequest(config)
        
        logDebug("Making secure request to: \(config.endpoint.rawValue)", category: .network, metadata: [
            "method": config.method.rawValue,
            "requiresAuth": config.requiresAuth
        ])
        
        let (data, response) = try await performWithRetry(request: request, retries: networkConfig.maxRetries)
        
        try validateResponse(response, data: data)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(responseType, from: data)
            
            logDebug("Request successful", category: .network, metadata: [
                "endpoint": config.endpoint.rawValue,
                "responseSize": data.count
            ])
            
            return result
        } catch {
            logError("Failed to decode response", category: .network, metadata: [
                "endpoint": config.endpoint.rawValue,
                "error": error.localizedDescription
            ])
            throw AppNetworkError.parseError.toAppError(metadata: ["decodingError": error.localizedDescription])
        }
    }
    
    private func buildSecureRequest(_ config: RequestConfiguration) throws -> URLRequest {
        var request = URLRequest(url: config.endpoint.url)
        request.httpMethod = config.method.rawValue
        request.timeoutInterval = config.timeout
        
        // Add default headers
        for (key, value) in networkConfig.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add custom headers
        if let headers = config.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add authentication if required
        if config.requiresAuth {
            do {
                let token = try securityManager.loadAuthToken()

                // Only validate as JWT if token has JWT format (3 parts separated by dots)
                // Laravel Sanctum uses simple bearer tokens, not JWTs
                let tokenParts = token.split(separator: ".")
                if tokenParts.count == 3 {
                    // Token looks like a JWT, validate it
                    if !securityManager.validateJWT(token) {
                        logWarning("Invalid JWT token detected", category: .security)
                        throw AppNetworkError.unauthorized.toAppError()
                    }
                } else {
                    // Sanctum token - just verify it's not empty
                    if token.isEmpty {
                        logWarning("Empty auth token", category: .security)
                        throw AppNetworkError.unauthorized.toAppError()
                    }
                    logDebug("Using Sanctum bearer token", category: .security)
                }

                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } catch {
                logError("Failed to load auth token", category: .security)
                throw AppNetworkError.unauthorized.toAppError()
            }
        }
        
        // Add request body
        if let body = config.body {
            request.httpBody = body
        }
        
        // Add request ID for tracking
        let requestID = UUID().uuidString
        request.setValue(requestID, forHTTPHeaderField: "X-Request-ID")
        
        logDebug("Built secure request", category: .network, metadata: [
            "requestId": requestID,
            "url": request.url?.absoluteString ?? "unknown",
            "method": request.httpMethod ?? "unknown"
        ])
        
        return request
    }
    
    private func performWithRetry(request: URLRequest, retries: Int) async throws -> (Data, URLResponse) {
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                let (data, response) = try await session.data(for: request)
                return (data, response)
            } catch {
                lastError = error
                
                logWarning("Request failed, attempt \(attempt + 1)/\(retries + 1)", category: .network, metadata: [
                    "error": error.localizedDescription,
                    "url": request.url?.absoluteString ?? "unknown"
                ])
                
                if attempt < retries {
                    let delay = pow(2.0, Double(attempt)) * networkConfig.retryDelay
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? AppNetworkError.invalidResponse.toAppError()
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppNetworkError.invalidResponse.toAppError()
        }
        
        let statusCode = httpResponse.statusCode
        
        logDebug("Received response", category: .network, metadata: [
            "statusCode": statusCode,
            "contentLength": data.count
        ])
        
        switch statusCode {
        case 200...299:
            break
        case 401:
            throw AppNetworkError.unauthorized.toAppError()
        case 403:
            throw AppNetworkError.forbidden.toAppError()
        case 404:
            throw AppNetworkError.notFound.toAppError()
        case 429:
            throw AppNetworkError.rateLimited.toAppError()
        case 500...599:
            throw AppNetworkError.serverError.toAppError(metadata: ["statusCode": statusCode])
        default:
            throw AppNetworkError.invalidResponse.toAppError(metadata: ["statusCode": statusCode])
        }
    }
    
    // MARK: - Authentication Methods
    func refreshToken() async throws -> String {
        do {
            let refreshToken = try securityManager.loadRefreshToken()
            
            let config = RequestConfiguration(
                endpoint: .login,
                method: .POST,
                body: try JSONSerialization.data(withJSONObject: ["refresh_token": refreshToken]),
                requiresAuth: false
            )
            
            struct RefreshResponse: Codable {
                let accessToken: String
                let refreshToken: String?
                
                enum CodingKeys: String, CodingKey {
                    case accessToken = "access_token"
                    case refreshToken = "refresh_token"
                }
            }
            
            let response: RefreshResponse = try await performRequest(config, responseType: RefreshResponse.self)
            
            try securityManager.saveAuthToken(response.accessToken)
            
            if let newRefreshToken = response.refreshToken {
                try securityManager.saveRefreshToken(newRefreshToken)
            }
            
            logInfo("Token refreshed successfully", category: .authentication)
            return response.accessToken
            
        } catch {
            logError("Token refresh failed", category: .authentication, metadata: [
                "error": error.localizedDescription
            ])
            throw error
        }
    }
    
    func logout() async throws {
        do {
            let config = RequestConfiguration(
                endpoint: .logout,
                method: .POST,
                requiresAuth: true
            )
            
            let _: EmptyResponse = try await performRequest(config, responseType: EmptyResponse.self)
            
            // Clear stored tokens
            securityManager.endSession()
            
            logInfo("Logout successful", category: .authentication)
            
        } catch {
            // Clear tokens even if logout request fails
            securityManager.endSession()
            
            logWarning("Logout request failed, but tokens cleared", category: .authentication, metadata: [
                "error": error.localizedDescription
            ])
        }
    }
    
    // MARK: - File Upload with Security
    func uploadFile(
        to endpoint: NetworkConfiguration.Endpoint,
        fileData: Data,
        fileName: String,
        mimeType: String,
        additionalFields: [String: String] = [:]
    ) async throws -> Data {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint.url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        let token = try securityManager.loadAuthToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create multipart body
        var body = Data()
        
        // Add additional fields
        for (key, value) in additionalFields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        logInfo("Uploading file", category: .network, metadata: [
            "fileName": fileName,
            "fileSize": fileData.count,
            "mimeType": mimeType
        ])
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return data
    }
}

// MARK: - URLSessionDelegate for Certificate Pinning
extension SecureNetworkManager: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Skip certificate pinning in debug mode if configured
        if !networkConfig.sslPinningEnabled {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            logError("Server trust not available", category: .security)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let host = challenge.protectionSpace.host
        
        // Validate certificate
        if securityManager.validateCertificate(serverTrust, for: host) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            logError("Certificate validation failed for host: \(host)", category: .security)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Supporting Types
struct EmptyResponse: Codable {}

// MARK: - Request Builder Extensions
extension SecureNetworkManager {
    func buildLoginRequest(email: String, password: String) -> RequestConfiguration {
        let credentials: [String: Any] = [
            "email": email,
            "password": password,
            "device_info": [
                "platform": "iOS",
                "version": UIDevice.current.systemVersion,
                "model": UIDevice.current.model,
                "app_version": AppConfigurationManager.shared.versionNumber
            ]
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: credentials) else {
            fatalError("Failed to serialize login credentials")
        }
        
        return RequestConfiguration(
            endpoint: .login,
            method: .POST,
            body: body,
            requiresAuth: false
        )
    }
    
    func buildTimeRecordRequest(
        projectId: String,
        action: String,
        location: [String: Any],
        notes: String?
    ) -> RequestConfiguration {
        var recordData: [String: Any] = [
            "project_id": projectId,
            "action": action,
            "location": location,
            "timestamp": Date().timeIntervalSince1970,
            "device_info": [
                "platform": "iOS",
                "version": UIDevice.current.systemVersion
            ]
        ]
        
        if let notes = notes {
            recordData["notes"] = notes
        }
        
        guard let body = try? JSONSerialization.data(withJSONObject: recordData) else {
            fatalError("Failed to serialize time record data")
        }
        
        return RequestConfiguration(
            endpoint: .storeTimeWork,
            method: .POST,
            body: body,
            requiresAuth: true
        )
    }
}