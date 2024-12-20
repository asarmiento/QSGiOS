import Foundation

// Respuesta de la API
struct RecordResponse: Codable {
    let success: Bool
    let message: String
    let data: RecordResponseData?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
    }
}

// Datos del registro para la API
struct RecordResponseData: Codable {
    let id: Int
    let work_type_id: Int?
    let project_id: Int?
    let dist: Double?
    let employee_id: Int
    let latitude: String
    let longitude: String
    let time: String
    let date: String
    let address: String
    let type: String
    let updated_at: String?
    let created_at: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case work_type_id
        case project_id
        case dist
        case employee_id
        case latitude
        case longitude
        case time
        case date
        case address
        case type
        case updated_at
        case created_at
    }
} 