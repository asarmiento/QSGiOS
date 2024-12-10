//
//  ModelJsonDetails.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//
import Foundation


struct WorkEntryDetails: Codable, Identifiable {
    let id: Int
    let employeeId: Int
    let workTypeId: Int
    let projectId: Int
    let time: String
    let date: String
    let hours: Double? // Cambiado a opcional
    let type: String
    let latitude: String
    let longitude: String
    let address: String?
    let observation: String?
    let dist: String
    let alerts: Int
    let createdAt: String
    let updatedAt: String
    let employee: EmployeeCodable
    let project: Project
    
    enum CodingKeys: String, CodingKey {
        case id
        case employeeId = "employee_id"
        case workTypeId = "work_type_id"
        case projectId = "project_id"
        case time
        case date
        case hours
        case type
        case latitude
        case longitude
        case address
        case observation
        case dist
        case alerts
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case employee
        case project
    }
    
 
    init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        employeeId = try container.decode(Int.self, forKey: .employeeId)
        workTypeId = try container.decode(Int.self, forKey: .workTypeId)
        projectId = try container.decode(Int.self, forKey: .projectId)
        time = try container.decode(String.self, forKey: .time)
        date = try container.decode(String.self, forKey: .date)
        type = try container.decode(String.self, forKey: .type)
        latitude = try container.decode(String.self, forKey: .latitude)
        longitude = try container.decode(String.self, forKey: .longitude)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        observation = try container.decodeIfPresent(String.self, forKey: .observation)
        dist = try container.decode(String.self, forKey: .dist)
        alerts = try container.decode(Int.self, forKey: .alerts)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        employee = try container.decode(EmployeeCodable.self, forKey: .employee)
        project = try container.decode(Project.self, forKey: .project)
        
        // Manejo personalizado para `hours`
        if let doubleValue = try? container.decode(Double.self, forKey: .hours) {
            hours = doubleValue
        } else if let stringValue = try? container.decode(String.self, forKey: .hours), let doubleFromString = Double(stringValue) {
            hours = doubleFromString
        } else {
            hours = nil
        }
    }
}
