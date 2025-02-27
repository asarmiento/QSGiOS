import Foundation
import SwiftData

@Model
final class RecordData {
    var id: Int?
    var employee_id: Int
    var project_id: Int
    var latitude: String
    var longitude: String
    var address: String
    var type: String
    var updated_at: String
    var created_at: String
    
    init(id: Int? = nil,
         employee_id: Int,
         project_id: Int,
         latitude: String,
         longitude: String,
         address: String,
         type: String,
         updated_at: String,
         created_at: String) {
        self.id = id
        self.employee_id = employee_id
        self.project_id = project_id
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.type = type
        self.updated_at = updated_at
        self.created_at = created_at
    }
} 