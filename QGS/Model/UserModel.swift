//
//  UserModel.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/27/24.
//
import Foundation
import SwiftData

@Model
class UserModel: Identifiable {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var email: String
    var token: String
    var type: String = "employee"
    var employeeId: Int
    var sysconf: Int
    
    init( name: String, email: String, token: String, employeeId: Int, sysconf: Int, type: String = "employee") {
        
        self.name = name
        self.email = email
        self.token = token
        self.employeeId = employeeId
        self.sysconf = sysconf
        self.type = type
    }
    
    var isValid: Bool {
        !name.isEmpty && !email.isEmpty && !token.isEmpty && !type.isEmpty
    }
}


