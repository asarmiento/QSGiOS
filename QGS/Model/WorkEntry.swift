//
//  ModelJsonDetails.swift
//  QGS
//
//  Created by Edin Martinez on 12/3/24.
//
import Foundation

struct WorkEntry: Codable, Identifiable {
    let id: Int
        let employee_id: Int
        let work_type_id: Int
        let project_id: Int
        let time: String
        let date: String
        let hours: String?
        let type: String
        let latitude: String
        let longitude: String
        let address: String
        let observation: String?
        let dist: String
        let alerts: Int
        let created_at: String
        let updated_at: String
        
        // Propiedades relacionadas con el empleado y el proyecto
        let employee: EmployeeCodable
        let project: Project
    
    
}



