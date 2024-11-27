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
     var id: UUID = UUID()
     var latitude: Double
     var longitude: Double
     var type: String
     var date: Date
     var times: String
    var employeeId: String
    
    init(latitude: Double, longitude: Double, type: String, date: Date, times: String, employeeId: String) {
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
        self.date = date
        self.times = times
        self.employeeId = employeeId
        }
  
    
}
