import Foundation

struct TimeRecord: Identifiable, Codable {
    let id: Int
    let employee: EmployeeCodable
    let date: String
    let time: String
    let type: String
    var hours: Double?
    var observation: String?
    let project: ProjectTimeRecord?
    
    enum CodingKeys: String, CodingKey {
        case id
        case employee
        case date
        case time
        case type
        case hours
        case observation
        case project
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        employee = try container.decode(EmployeeCodable.self, forKey: .employee)
        date = try container.decode(String.self, forKey: .date)
        time = try container.decode(String.self, forKey: .time)
        type = try container.decode(String.self, forKey: .type)
        project = try container.decodeIfPresent(ProjectTimeRecord.self, forKey: .project)
        observation = try container.decodeIfPresent(String.self, forKey: .observation)
        
        // Manejar el campo hours que puede venir como string o como double
        if let hoursDouble = try? container.decodeIfPresent(Double.self, forKey: .hours) {
            hours = hoursDouble
        } else if let hoursString = try? container.decodeIfPresent(String.self, forKey: .hours) {
            hours = Double(hoursString)
        } else {
            hours = nil
        }
    }
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
    let address: String?
    let altitude: String?
    let longitude: String?
    let created_at: String?
    let updated_at: String?
}

