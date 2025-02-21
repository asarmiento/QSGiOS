import Foundation

struct TimeRecord: Codable, Identifiable {
    let id: Int
    let employee_id: Int
    let work_type_id: Int
    let project_id: Int
    let time: String
    let date: String
    let hours: String? // Porque ahora a veces viene "0" (string) o null
    let type: String
    
    let latitude: String?
    let longitude: String?
    let address: String?
    let observation: String?
    let dist: Double?
    let alerts: Int?
    let created_at: String?
    let updated_at: String?
    
    let employee: EmployeeTimeRecord
    let project: ProjectTimeRecord
}

/// Empleado
struct EmployeeTimeRecord: Codable, Identifiable {
    let id: Int
    let card: String
    let type_of_card: String
    let name: String
    let vacation: Int?
    let email: String
    let phone: String
    let address: String?
    let province_id: Int?
    let canton_id: Int?
    let district_id: Int?
    let marital_status_id: Int?
    let nationality_id: Int?
    let user_id: Int
    let status: Int?
    let created_at: String?
    let updated_at: String?
}

/// Proyecto
struct ProjectTimeRecord: Codable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let altitude: String
    let longitude: String
    let created_at: String?
    let updated_at: String?
}

