//
//  UserModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//

import Foundation
import SwiftData

@Model
class UserModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var sysconfId: Int
    var token: String
    
    init( name: String = "", email: String = "", sysconfId: Int = -1, token: String = "") {
        self.id = UUID()
        self.name = name
        self.email = email
        self.sysconfId = sysconfId
        self.token = token
    }
}
