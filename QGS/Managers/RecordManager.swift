//
//  RecordManager.swift
//  QGS
//
//  Created by Edin Martinez on 12/8/24.
//

import Foundation
import SwiftData

class RecordManager {
    static let shared = RecordManager()
    private var record: RecordModel?
    private var context: ModelContext?
    
    private init() { }
    
    func configure(with context: ModelContext) {
        self.context = context
        let currentVersion = 2 // Cambia esto a la versión actual de tu modelo
        let previousVersion = UserDefaults.standard.integer(forKey: "modelVersion")

        if previousVersion < currentVersion {
            Migration.migrate(from: previousVersion, to: currentVersion, context: context)
            UserDefaults.standard.set(currentVersion, forKey: "modelVersion")
        }

        loadRecords()
        print("RecordManager configurado con el contexto correctamente.")
    }
    
    private func loadRecords() {
        guard let context = context else {
            print("Error: ModelContext no está configurado.")
            return
        }
        do {
            record = try context.fetch(FetchDescriptor<RecordModel>()).first
        } catch {
            print("Error al obtener el registro: \(String(describing: error))")
        }
    }
    
    func saveRecord(recordData: RecordResponseData) {
        guard let context = context else {
            print("Error: ModelContext no está configurado.")
            return
        }
        
        let latitude = Double(recordData.latitude) ?? 0.0
        let longitude = Double(recordData.longitude) ?? 0.0
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.date(from: recordData.date) ?? Date()
        
        // Redondear dist a 2 decimales si existe
        let distance = recordData.dist.map { Double(round($0 * 100) / 100) } ?? 0.0
        
        let message = "hola a todos llegue tarde"
        let record = RecordModel(
            latitude: latitude,
            longitude: longitude,
            type: recordData.type,
            date: date,
            times: recordData.time,
            employeeId: String(recordData.employee_id),
            address: recordData.address,
            distance: distance,
            message: message,
            observation: recordData.observation
        )
       
        context.insert(record)
        do {
            try context.save()
            print("Registro guardado exitosamente.")
        } catch {
            print("Error al guardar el registro: \(error)")
        }
    }
    
    func getRecordExistsFor(type: String, date: Date) -> Bool {
        guard let context = context else {
            print("Error: ModelContext no está configurado.")
            return false
        }

        // Establece el rango para el día actual
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) else {
            return false
        }

        // Configura un descriptor para buscar el registro con el tipo y la fecha
        let descriptor = FetchDescriptor<RecordModel>(
            predicate: #Predicate { record in
                record.type == type && record.date >= startOfDay && record.date <= endOfDay
            }
        )

        do {
            let records = try context.fetch(descriptor)
            print("Existen \(records.count) registros con tipo '\(type)' para el día actual.")
            return !records.isEmpty
        } catch {
            print("Error al verificar los registros: \(error)")
            return false
        }
    }
    
    func getRecordExists(for type: String) -> Int {
        guard let context = context else {
            print("Error: ModelContext no está configurado.")
            return 0
        }
        
        // Establece el rango para el día actual
        let date = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) else {
            return 0
        }
        
        // Configura un descriptor para buscar el registro con el type y la fecha
        let descriptor = FetchDescriptor<RecordModel>(
            predicate: #Predicate { record in
                record.type == type && record.date >= startOfDay && record.date <= endOfDay
            }
        )
        
        do {
            let records = try context.fetch(descriptor)
            print("Existen \(records.count) registros con tipo '\(type)' para el día actual.")
            return records.count
        } catch {
            print("Error al verificar el registro: \(String(describing: error))")
            return 0
        }
    }
    
    // ... resto del código sin cambios ...
}
