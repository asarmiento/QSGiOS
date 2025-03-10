//
//  EmployeeLocation.swift
//  QGS
//
//  Created by Edin Martinez on 3/10/25.
//
import Foundation
import CoreLocation


// Definición del modelo EmployeeLocation aquí para asegurar que esté disponible
struct EmployeeLocation: Codable, Identifiable {
    let employeeName: String
    let latitude: String
    let longitude: String
    let entryTime: String
    let projectName: String
    
    var id: String { employeeName }
    
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
