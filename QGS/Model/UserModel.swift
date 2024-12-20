//
//  UserModel.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/27/24.
//
import Foundation
import SwiftData

@Model
class UserModel: Codable {
    var name: String
    var email: String
    var token: String
    var employeeId: Int
    var sysconf: String
    var type: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case email
        case token
        case employeeId = "employee_id"
        case sysconf
        case type
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        token = try container.decode(String.self, forKey: .token)
        employeeId = try container.decode(Int.self, forKey: .employeeId)
        sysconf = try container.decode(String.self, forKey: .sysconf)
        type = try container.decodeIfPresent(String.self, forKey: .type)
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
    
    init(name: String, email: String, token: String, employeeId: Int, sysconf: String, type: String? = nil) {
        self.name = name
        self.email = email
        self.token = token
        self.employeeId = employeeId
        self.sysconf = sysconf
        self.type = type
    }
}


