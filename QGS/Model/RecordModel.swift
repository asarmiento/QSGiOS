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
    var ddate: String
    var latitud: Double
    var longitud: Double
    var dtime: String
    var type: String
    
    init(id: UUID, ddate: String, latitud: Double, longitud: Double, dtime: String, type: String) {
        self.id = id
        self.ddate = ddate
        self.latitud = latitud
        self.longitud = longitud
        self.dtime = dtime
        self.type = type
    }
}
