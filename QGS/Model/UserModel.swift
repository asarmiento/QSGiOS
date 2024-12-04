//
//  UserModel.swift
//  QGS
//
//  Created by Edin Martinez on 11/27/24.
//
import Foundation
import SwiftData

@Model
class UserModel: Identifiable {
    @Attribute(.unique) var id: UUID
     var name: String
     var email: String
     var token: String
     var employeeId: Int
    var sysconf: Int
    
    init(id: UUID = UUID(), name: String, email: String, token: String, employeeId: Int, sysconf: Int) {
        self.id = id
        self.name = name
        self.email = email
        self.token = token
        self.employeeId = employeeId
        self.sysconf = sysconf
    }
}


