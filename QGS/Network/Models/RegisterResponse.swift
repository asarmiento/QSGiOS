import Foundation

struct RegisterResponse: Codable {
    let success: Bool
    let message: String
    let data: RegisterData?
    let user: LoginResponse.UserResponse?
    let name: String?
    let sysconf: Int?
    let email: String?
    let token: String?
    
    enum CodingKeys: String, CodingKey {
        case success = "status"
        case message
        case data
        case user
        case name
        case sysconf
        case email
        case token
    }
}

// Modelo para cualquier tipo de datos de respuesta
struct RegisterData: Codable {
    // Datos del formulario original (para errores)
    let name: String?
    let email: String?
    let phone: String?
    let card: String?
    let altitude: Double?
    let longitude: Double?
    let name_work_type: String?
    let password: String?
    let name_project: String?
    let budget: Double?
    let address: String?
    
    // Datos de usuario (para respuesta exitosa)
    let user: LoginResponse.UserResponse?
    let token: String?
    let sysconf: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, email, phone, card, altitude, longitude
        case name_work_type, password, name_project, budget, address
        case user, token, sysconf
    }
} 