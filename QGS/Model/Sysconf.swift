//
//  Sysconf.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//

import Foundation

// Modelo para los sistemas de configuración (sysconfs)
struct Sysconf: Decodable {
    let id: Int
    let name: String
    let card: String
    let url: String
    let typeCard: String
    let phone: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case card
        case url
        case typeCard = "type_card"
        case phone
        case email
    }
}
