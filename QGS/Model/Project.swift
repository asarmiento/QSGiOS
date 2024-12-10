//
//  Project.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//
import Foundation


struct Project: Codable {
    let id: Int
    let name: String
    let address: String
    let altitude: String
    let longitude: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, altitude, longitude
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
