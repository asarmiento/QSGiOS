//
//  SetterUtils.swift
//  QGS
//
//  Created by Edin Martinez on 11/27/24.
//
import SwiftUI


func createRecord(type: String,time:String,date:String,latitude:Double?,longitude:Double?){
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let date = dateFormatter.date(from: date)
    let record = RecordEntity(context: PersistentStorage.shared.context)
    record.id = UUID()
    record.type = type
    record.date = date
    record.times = time
    record.latitude = latitude ?? 39.384974
    record.longitude = longitude ?? -84.530861
    record.willSave()
    PersistentStorage.shared.saveContext()
    print("Resultado de DB \(record)")
}
 func getCurrentTime() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HHmmss"
    return formatter.string(from: Date())
}

 func getCurrentDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
}




