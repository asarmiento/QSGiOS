import Foundation

// MARK: - Network Manager Adapter
// This adapter provides backward compatibility while migrating to SecureNetworkManager

class NetworkManagerAdapter {
    static let shared = NetworkManagerAdapter()
    
    private let secureNetworkManager = SecureNetworkManager.shared
    private let errorManager = ErrorManager.shared
    
    private init() {}
    
    // MARK: - Legacy Network Error Mapping
    private func mapLegacyError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(urlError)
            case .timedOut:
                return .networkError(urlError)
            case .badURL:
                return .invalidURL
            default:
                return .invalidResponse
            }
        }
        
        return .serverError(500)
    }
    
    // MARK: - Login API Compatibility
    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        Task {
            do {
                let config = secureNetworkManager.buildLoginRequest(email: email, password: password)
                let response: LoginResponse = try await secureNetworkManager.performRequest(config, responseType: LoginResponse.self)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                let mappedError = mapLegacyError(error)
                DispatchQueue.main.async {
                    completion(.failure(mappedError))
                }
            }
        }
    }
    
    // MARK: - Registration API Compatibility
    func register(
        name: String,
        email: String,
        phone: String,
        card: String,
        altitude: Double,
        longitude: Double,
        nameWorkType: String,
        password: String,
        nameProject: String,
        budget: Double,
        address: String,
        completion: @escaping (Result<RegisterResponse, Error>) -> Void
    ) {
        Task {
            do {
                let registrationData: [String: Any] = [
                    "name": name,
                    "email": email,
                    "phone": phone,
                    "card": card,
                    "altitude": altitude,
                    "longitude": longitude,
                    "name_work_type": nameWorkType,
                    "password": password,
                    "name_project": nameProject,
                    "budget": budget,
                    "address": address
                ]
                
                guard let body = try? JSONSerialization.data(withJSONObject: registrationData) else {
                    throw NetworkError.parseError
                }
                
                let config = RequestConfiguration(
                    endpoint: .register,
                    method: .POST,
                    body: body,
                    requiresAuth: false
                )
                
                let response: RegisterResponse = try await secureNetworkManager.performRequest(config, responseType: RegisterResponse.self)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                let mappedError = mapLegacyError(error)
                DispatchQueue.main.async {
                    completion(.failure(mappedError))
                }
            }
        }
    }
    
    // MARK: - Record API Compatibility
    func record(params: [String: Any], completion: @escaping (Result<RecordResponse, Error>) -> Void) {
        Task {
            do {
                guard let body = try? JSONSerialization.data(withJSONObject: params) else {
                    throw NetworkError.parseError
                }
                
                let config = RequestConfiguration(
                    endpoint: .storeTimeWork,
                    method: .POST,
                    body: body,
                    requiresAuth: true
                )
                
                let response: RecordResponse = try await secureNetworkManager.performRequest(config, responseType: RecordResponse.self)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                let mappedError = mapLegacyError(error)
                DispatchQueue.main.async {
                    completion(.failure(mappedError))
                }
            }
        }
    }
    
    // MARK: - Time Records API Compatibility  
    func fetchTimeRecords(employeeId: String, completion: @escaping (Result<WorkTimeResponse, Error>) -> Void) {
        Task {
            do {
                let config = RequestConfiguration(
                    endpoint: .timeRecords,
                    method: .GET,
                    requiresAuth: true
                )
                
                let response: WorkTimeResponse = try await secureNetworkManager.performRequest(config, responseType: WorkTimeResponse.self)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                let mappedError = mapLegacyError(error)
                DispatchQueue.main.async {
                    completion(.failure(mappedError))
                }
            }
        }
    }
    
    // MARK: - Employee List API Compatibility
    func fetchEmployees(completion: @escaping (Result<[Employee], Error>) -> Void) {
        Task {
            do {
                let config = RequestConfiguration(
                    endpoint: .listEmployees,
                    method: .GET,
                    requiresAuth: true
                )
                
                let response: [Employee] = try await secureNetworkManager.performRequest(config, responseType: [Employee].self)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                let mappedError = mapLegacyError(error)
                DispatchQueue.main.async {
                    completion(.failure(mappedError))
                }
            }
        }
    }
    
    // MARK: - Generic Request Method
    func performRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true,
        responseType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        Task {
            do {
                var body: Data?
                if let parameters = parameters {
                    body = try JSONSerialization.data(withJSONObject: parameters)
                }
                
                // Map endpoint string to NetworkConfiguration.Endpoint
                guard let networkEndpoint = mapEndpoint(endpoint) else {
                    throw NetworkError.invalidURL
                }
                
                let config = RequestConfiguration(
                    endpoint: networkEndpoint,
                    method: method,
                    body: body,
                    requiresAuth: requiresAuth
                )
                
                let response: T = try await secureNetworkManager.performRequest(config, responseType: responseType)
                
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                let mappedError = mapLegacyError(error)
                DispatchQueue.main.async {
                    completion(.failure(mappedError))
                }
            }
        }
    }
    
    // MARK: - Endpoint Mapping Helper
    private func mapEndpoint(_ endpointString: String) -> NetworkConfiguration.Endpoint? {
        // Map legacy endpoint strings to new enum values
        switch endpointString {
        case EndPoints.login:
            return .login
        case EndPoints.storeRegister:
            return .register
        case EndPoints.storeRecord:
            return .storeTimeWork
        case EndPoints.getListTotal:
            return .totalTimeWork
        case EndPoints.getListEmployees:
            return .listEmployees
        default:
            return nil
        }
    }
}

