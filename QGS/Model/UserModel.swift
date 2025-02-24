//
//  UserModel.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/27/24.
//
import Foundation
import SwiftData

@Model
final class UserModel {
    // Propiedades persistentes
    @Attribute(.unique) var email: String
    @Attribute var name: String
    @Attribute var token: String
    @Attribute var employeeId: Int
    @Attribute var sysconf: String
    @Attribute var type: String?
    
    init(name: String, email: String, token: String, employeeId: Int, sysconf: String, type: String? = nil) {
        self.name = name
        self.email = email
        self.token = token
        self.employeeId = employeeId
        self.sysconf = sysconf
        self.type = type
    }
}

// Extensión para Codable
extension UserModel: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case email
        case token
        case employeeId = "employee_id"
        case sysconf
        case type
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let email = try container.decode(String.self, forKey: .email)
        let token = try container.decode(String.self, forKey: .token)
        let employeeId = try container.decode(Int.self, forKey: .employeeId)
        let sysconf = try container.decode(String.self, forKey: .sysconf)
        let type = try container.decodeIfPresent(String.self, forKey: .type)
        
        self.init(name: name, email: email, token: token, employeeId: employeeId, sysconf: sysconf, type: type)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(token, forKey: .token)
        try container.encode(employeeId, forKey: .employeeId)
        try container.encode(sysconf, forKey: .sysconf)
        try container.encodeIfPresent(type, forKey: .type)
    }
}


