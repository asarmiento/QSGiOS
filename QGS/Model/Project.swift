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
    
    
    enum CodingKeys: String, CodingKey {
           case id, name, address
       }
}
