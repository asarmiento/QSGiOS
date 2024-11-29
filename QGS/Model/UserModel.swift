//
//  UserModel.swift
//  QGS
//
//  Created by Edin Martinez on 11/27/24.
//
import Foundation
import SwiftData
import SwiftUI

@Model
final class UserModel {
    @Attribute(.unique)  var id: UUID
    var name: String
    var email: String
    @Attribute(originalName: "emporyee_id") var employeeId: String
    @Attribute(originalName: "system_id") var systemId: String
    var token: String
    
    
    init( name: String, email: String, employeeId: String, systemId: String, token: String) {
        self.name = name
        self.email = email
        self.employeeId = employeeId
        self.systemId = systemId
        self.token = token
        self.id = UUID()
    }
    
    
}


