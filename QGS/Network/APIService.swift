import Foundation

class APIService {
    static let shared = APIService()
    private let networkAdapter = NetworkManagerAdapter.shared
    private let baseURL = EndPoints.login
    
    func login(email: String, password: String, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        // Use new secure network adapter
        networkAdapter.login(email: email, password: password, completion: completion)
    }
    
    func register(name: String, email: String, phone: String, card: String, altitude: Double, longitude: Double, nameWorkType: String, password: String, nameProject: String, budget: Double, address: String, completion: @escaping (Result<RegisterResponse, Error>) -> Void) {
        // Use new secure network adapter
        networkAdapter.register(
            name: name,
            email: email,
            phone: phone,
            card: card,
            altitude: altitude,
            longitude: longitude,
            nameWorkType: nameWorkType,
            password: password,
            nameProject: nameProject,
            budget: budget,
            address: address,
            completion: completion
        )
    }
} 
