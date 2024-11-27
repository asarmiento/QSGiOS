//
//  UserModel.swift
//  QGS
//
//  Created by Edin Martinez on 11/27/24.
//
import Foundation
import SwiftData

@Model
class UserModel {
    var id: UUID = UUID()
    var name: String
    var email: String
        
    init( name: String, email: String) {

        self.name = name
        self.email = email
    }

}


