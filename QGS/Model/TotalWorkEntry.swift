//
//  TotalWorkEntry.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//

import Foundation

struct TotalWorkEntry: Identifiable, Decodable {
    let id: UUID = UUID() // Generar automáticamente un ID único si no se incluye en la API
    let weekI: String     // Fecha de inicio
    let weekF: String     // Fecha de fin
    let hours: Int        // Total de horas

    enum CodingKeys: String, CodingKey {
        case weekI // Mapea a la clave JSON "weekI"
        case weekF // Mapea a la clave JSON "weekF"
        case hours
    }
    
    init(from decoder: Decoder) throws {
           let container = try decoder.container(keyedBy: CodingKeys.self)
           weekI = try container.decode(String.self, forKey: .weekI)
           weekF = try container.decode(String.self, forKey: .weekF)
           if let hoursString = try? container.decode(String.self, forKey: .hours), let hoursInt = Int(hoursString) {
               hours = hoursInt
           } else {
               hours = try container.decode(Int.self, forKey: .hours)
           }
       }
}
