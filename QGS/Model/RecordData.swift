import Foundation
import SwiftData

@Model
class RecordData {
    var id: Int?
    var work_type_id: Int
    var project_id: Int
    var dist: Double
    var employee_id: Int
    var latitude: String
    var longitude: String
    var time: String
    var date: String
    var address: String
    var type: String
    var updated_at: String?
    var created_at: String?
    
    init(id: Int? = nil,
         work_type_id: Int,
         project_id: Int,
         dist: Double,
         employee_id: Int,
         latitude: String,
         longitude: String,
         time: String,
         date: String,
         address: String,
         type: String,
         updated_at: String? = nil,
         created_at: String? = nil) {
        self.id = id
        self.work_type_id = work_type_id
        self.project_id = project_id
        self.dist = dist
        self.employee_id = employee_id
        self.latitude = latitude
        self.longitude = longitude
        self.time = time
        self.date = date
        self.address = address
        self.type = type
        self.updated_at = updated_at
        self.created_at = created_at
    }
} 