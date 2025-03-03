import Foundation
import CoreLocation

struct EmployeeLocation: Codable, Identifiable {
    let employeeName: String
    let latitude: String
    let longitude: String
    let entryTime: String
    let projectName: String
    
    var id: String { employeeName } // Usando el nombre como identificador único
    
    // Convertir las coordenadas a CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: Double(latitude) ?? 0.0,
            longitude: Double(longitude) ?? 0.0
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case employeeName = "employee_name"
        case latitude
        case longitude
        case entryTime = "entry_time"
        case projectName = "project_name"
    }
} 