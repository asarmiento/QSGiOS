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
    let createdAt: String?
    let updatedAt: String?
    let hours: String?
    let month: String?
    
    // No usamos CodingKeys ya que el decodificador se encargará de la conversión
    // con keyDecodingStrategy = .convertFromSnakeCase
}
