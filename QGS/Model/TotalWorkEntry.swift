//
//  TotalWorkEntry.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//

import Foundation

struct TotalWorkEntry: Codable, Identifiable {
    var id: String { return "\(weekI)-\(weekF)" } // Usar la combinación de semana de inicio y fin como identificador único
    let weekI: String
    let weekF: String
    let hours: Int
}
