//
//  RecordModel.swift
//  QGS
//
//  Created by Edin Martinez on 7/31/24.
//
import Foundation
import SwiftData

@Model
class RecordModel {
    @Attribute(.unique) var id: UUID
    var date: String
    var latitud: Double
    var longitud: Double
    var time: String
    var type: String
    
    init( date: String, latitud: Double, longitud: Double, time: String, type: String) {
        self.id = UUID()
        self.date = date
        self.latitud = latitud
        self.longitud = longitud
        self.time = time
        self.type = type
    }
}
