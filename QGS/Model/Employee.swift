//
//  Employee.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//
import Foundation

// Modelo para el empleado
struct Employee: Decodable {
    let id: Int
    let card: String
    let typeOfCard: String
    let name: String
    let vacation: Int
    let email: String
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case card
        case typeOfCard = "type_of_card"
        case name
        case vacation
        case email
        case phone
    }
}


// Modelo para el empleado
struct EmployeeCodable: Codable {
    let id: Int
        let card: String
        let typeOfCard: String
        let name: String
        let vacation: Int
        let email: String
        let phone: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case card
        case typeOfCard = "type_of_card"
        case name
        case vacation
        case email
        case phone
    }
}
