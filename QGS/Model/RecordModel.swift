//
//  ModelRecord.swift
//  QGS
//
//  Created by Anwar Sarmiento on 11/26/24.
//

import Foundation
import SwiftData

@Model
class RecordModel {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var type: String
    var date: Date
    var times: String
    var employeeId: String
    var address: String
    var distance: Double?
    var message: String?
    var observation: String?
    var syncStatus: Bool?
    
    init(id: UUID = UUID(), latitude: Double, longitude: Double, type: String, date: Date, times: String, employeeId: String, address: String, distance: Double? = nil, message: String? = nil, observation: String? = nil, syncStatus: Bool? = false) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
        self.date = date
        self.times = times
        self.employeeId = employeeId
        self.address = address
        self.distance = distance
        self.message = message
        self.observation = observation
        self.syncStatus = syncStatus
    }
}

