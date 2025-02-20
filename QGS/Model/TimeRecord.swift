import Foundation

struct TimeRecord: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let workTypeId: Int
    let projectId: Int
    let time: String
    let date: String
    let type: String
    let employee: Employee
    
    enum CodingKeys: String, CodingKey {
        case id
        case employeeId = "employee_id"
        case workTypeId = "work_type_id"
        case projectId = "project_id"
        case time
        case date
        case type
        case employee
    }
} 