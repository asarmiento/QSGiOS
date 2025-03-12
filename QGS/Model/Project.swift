//
//  Project.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//
import Foundation

struct Project: Codable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let altitude: String
    let longitude: String
    let status: Int
    let budget: Double
    let createdAt: String?
    let updatedAt: String?
    let hours: String?
    let month: String?
    let year: String?
    let sysconfId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case altitude
        case longitude
        case status
        case budget
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case hours
        case month
        case year
        case sysconfId = "sysconf_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        altitude = try container.decode(String.self, forKey: .altitude)
        longitude = try container.decode(String.self, forKey: .longitude)
        status = try container.decode(Int.self, forKey: .status)
        
        // Manejar el campo budget que puede venir como String o Double
        if let budgetDouble = try? container.decode(Double.self, forKey: .budget) {
            budget = budgetDouble
        } else if let budgetString = try? container.decode(String.self, forKey: .budget),
                  let budgetValue = Double(budgetString) {
            budget = budgetValue
        } else {
            budget = 0.0 // Valor por defecto si no se puede decodificar
        }
        
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        hours = try container.decodeIfPresent(String.self, forKey: .hours)
        month = try container.decodeIfPresent(String.self, forKey: .month)
        year = try container.decodeIfPresent(String.self, forKey: .year)
        sysconfId = try container.decodeIfPresent(Int.self, forKey: .sysconfId)
    }
    
    // Constructor personalizado para crear proyectos manualmente
    init(id: Int, name: String, address: String, altitude: String, longitude: String, status: Int, budget: Double, createdAt: String? = nil, updatedAt: String? = nil, hours: String? = nil, month: String? = nil, year: String? = nil, sysconfId: Int? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.altitude = altitude
        self.longitude = longitude
        self.status = status
        self.budget = budget
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.hours = hours
        self.month = month
        self.year = year
        self.sysconfId = sysconfId
    }
}
