import Foundation
import SwiftData

// Modelo para la base de datos local
@Model
class RecordModel {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var type: String
    var date: Date
    var times: String
    var employeeId: String
    var address: String
    
    init(id: UUID = UUID(), latitude: Double, longitude: Double, type: String, date: Date, times: String, employeeId: String, address: String) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
        self.date = date
        self.times = times
        self.employeeId = employeeId
        self.address = address
    }
}

// Modelos para la API
struct RecordResponse: Codable {
    let success: Bool
    let message: String
    let data: RecordData?
}

struct RecordData: Codable {
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
}

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "No se recibieron datos del servidor"
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesión nuevamente"
        case .apiError(let message):
            return message
        }
    }
} 