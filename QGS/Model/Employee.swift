//
//  Employee.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//
import Foundation

// Modelo para el empleado
struct Employee: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let phone: String
    // Agrega otros campos según sea necesario
}


