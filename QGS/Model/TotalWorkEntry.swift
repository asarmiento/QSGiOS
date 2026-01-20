//
//  TotalWorkEntry.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//

import Foundation

struct TotalWorkEntry: Identifiable, Codable {
    let id: UUID = UUID() // Generar automáticamente un ID único si no se incluye en la API
    let weekI: String     // Fecha de inicio
    let weekF: String     // Fecha de fin
    let hours: String     // Total de horas (can be string or int from API)

    enum CodingKeys: String, CodingKey {
        case weekI // Mapea a la clave JSON "weekI"
        case weekF // Mapea a la clave JSON "weekF"
        case hours
    }
    
    init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)
           weekI = try container.decode(String.self, forKey: .weekI)
           weekF = try container.decode(String.self, forKey: .weekF)
           
           // Handle hours as either string or int from API
           if let hoursString = try? container.decode(String.self, forKey: .hours) {
               hours = hoursString
           } else if let hoursInt = try? container.decode(Int.self, forKey: .hours) {
               hours = String(hoursInt)
           } else {
               hours = "0"
           }
       }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(weekI, forKey: .weekI)
        try container.encode(weekF, forKey: .weekF)
        try container.encode(hours, forKey: .hours)
    }
}
