//
//  UserModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//

import Foundation
import SwiftData

@Model
class UserModel: Identifiable {
    var name: String
    var email: String
    var sysconf: Int
    var token: String
    
    init( name: String, email: String, sysconf: Int, token: String) {
        self.name = name
        self.email = email
        self.sysconf = sysconf
        self.token = token
    }
}
