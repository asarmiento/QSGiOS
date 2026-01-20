import Foundation
import Network
import UIKit

// MARK: - Network Configuration
struct NetworkConfiguration {
    static let shared = NetworkConfiguration()
    
    private init() {}
    
    // MARK: - API Configuration
    var baseURL: URL {
        let urlString = AppConfigurationManager.shared.current.apiBaseURL
        guard let url = URL(string: urlString) else {
            fatalError("Invalid API base URL configuration: \(urlString)")
        }
        return url
    }
    
    var timeout: TimeInterval {
        AppConfigurationManager.shared.isDebugMode ? 60.0 : 30.0
    }
    
    var maxRetries: Int {
        3
    }
    
    var retryDelay: TimeInterval {
        2.0
    }
    
    // MARK: - Headers
    var defaultHeaders: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": userAgent,
            "App-Version": AppConfigurationManager.shared.versionNumber,
            "Build-Number": AppConfigurationManager.shared.buildNumber
        ]
    }
    
    private var userAgent: String {
        let config = AppConfigurationManager.shared
        let device = UIDevice.current
        let osVersion = device.systemVersion
        let model = device.model
        
        return "\(config.current.appName)/\(config.versionNumber) (\(config.buildNumber)) iOS/\(osVersion) \(model)"
    }
    
    // MARK: - Endpoints
    enum Endpoint {
        case login
        case register
        case storeTimeWork
        case totalTimeWork
        case listEmployees
        case userProfile
        case updateProfile
        case changePassword
        case logout
        case projects
        case timeRecords
        case reports
        case weeklyTotals(String) // Employee ID parameter
        case registerNotificationToken
        
        var rawValue: String {
            switch self {
            case .login: return "/login"
            case .register: return "/store-register"
            case .storeTimeWork: return "/projects/store-data-time-work"
            case .totalTimeWork: return "/projects/total-time-work-employees"
            case .listEmployees: return "/colaboradores/list-employees"
            case .userProfile: return "/user/profile"
            case .updateProfile: return "/user/update-profile"
            case .changePassword: return "/user/change-password"
            case .logout: return "/user/logout"
            case .projects: return "/projects"
            case .timeRecords: return "/time-records"
            case .reports: return "/reports"
            case .weeklyTotals(let employeeId): return "/projects/total-time-work-employees/\(employeeId)"
            case .registerNotificationToken: return "/notifications/register-token"
            }
        }
        
        var url: URL {
            return NetworkConfiguration.shared.baseURL.appendingPathComponent(self.rawValue)
        }
        
        var fullURL: String {
            return url.absoluteString
        }
    }
    
    // MARK: - Environment Specific Settings
    var isLoggingEnabled: Bool {
        AppConfigurationManager.shared.isDebugMode
    }
    
    var allowsInsecureConnections: Bool {
        AppConfigurationManager.shared.isDebugMode
    }
    
    // MARK: - SSL Pinning Configuration
    var sslPinningEnabled: Bool {
        AppConfigurationManager.shared.isProduction
    }
    
    var pinnedCertificates: [String] {
        // TODO: Add actual certificate hashes for production
        AppConfigurationManager.shared.isProduction ? [] : []
    }
}

// MARK: - Network Monitor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Cache Policy
enum CachePolicy {
    case ignoreLocalCacheData
    case returnCacheDataElseLoad
    case returnCacheDataDontLoad
    case reloadIgnoringLocalCacheData
}

// MARK: - Request Configuration
struct RequestConfiguration {
    let endpoint: NetworkConfiguration.Endpoint
    let method: HTTPMethod
    let headers: [String: String]?
    let body: Data?
    let timeout: TimeInterval
    let requiresAuth: Bool
    let cachePolicy: CachePolicy
    
    var fullURL: String {
        return endpoint.fullURL
    }
    
    init(
        endpoint: NetworkConfiguration.Endpoint,
        method: HTTPMethod = .GET,
        headers: [String: String]? = nil,
        body: Data? = nil,
        timeout: TimeInterval? = nil,
        requiresAuth: Bool = true,
        cachePolicy: CachePolicy = .ignoreLocalCacheData
    ) {
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.body = body
        self.timeout = timeout ?? NetworkConfiguration.shared.timeout
        self.requiresAuth = requiresAuth
        self.cachePolicy = cachePolicy
    }
}

// MARK: - HTTP Method
enum HTTPMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}