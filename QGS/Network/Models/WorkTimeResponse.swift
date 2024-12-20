struct WorkTimeResponse: Codable {
    let success: Bool
    let message: String
    let data: WorkTimeData
}

struct WorkTimeData: Codable {
    let id: Int
    let workTypeId: Int
    let projectId: Int
    let dist: Double
    let employeeId: Int
    let latitude: String
    let longitude: String
    let time: String
    let date: String
    let address: String
    let type: String
    let updatedAt: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case workTypeId = "work_type_id"
        case projectId = "project_id"
        case dist
        case employeeId = "employee_id"
        case latitude
        case longitude
        case time
        case date
        case address
        case type
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
} 