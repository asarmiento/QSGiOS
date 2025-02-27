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
    let createdAt: String
    let updatedAt: String
    let hours: String?
    let month: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case altitude
        case longitude
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case hours
        case month
    }
}
