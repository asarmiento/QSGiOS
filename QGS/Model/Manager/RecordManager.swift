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
            print("Error al obtener el usuario: \(error)")
        }
    }
    
    func getRecords() -> RecordModel? {
        return record
    }
    
    func getRecordExistsfor() -> Bool{
        guard let context = context else {
            print("Error: ModelContext no está configurado.")
            return false
        }
        // Establece el rango para el día actual
        let  date: Date = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) else {
            return false
        }
        
        // Configura un descriptor para buscar el registro
        let descriptor = FetchDescriptor<RecordModel>(
            predicate: #Predicate { record in
                record.date >= startOfDay && record.date <= endOfDay
            }
        )
        
        do {
            // Verifica si existe al menos un registro
            
            let records = try context.fetch(descriptor)
            print("Existen \(records.count) registros")
            return !records.isEmpty
        } catch {
            print("Error al verificar el registro: \(error.localizedDescription)")
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
            // Verifica si existe al menos un registro que coincida con el criterio
            let records = try context.fetch(descriptor)
            print("Existen \(records.count) registros con tipo '\(type)' para el día actual.")
            return records.count
        } catch {
            print("Error al verificar el registro: \(error.localizedDescription)")
            return 0
        }
    }
    
    func refreshRecord() {
        loadRecords()
    }
    
    func saveRecord(from response: RecordData) {
        guard let context = context else {
            print("Error: ModelContext no está configurado.")
            return
        }
        
        Task { @MainActor in
            // Depuración de los datos
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let dataDate = dateFormatter.date(from: response.date) ?? Date()
            let latitude = Double(response.latitude) ?? 0.0
            let longitude = Double(response.longitude) ?? 0.0
            let address = response.address
            
            // Crear el modelo y guardarlo en el contexto
            let newRecord = RecordModel(latitude: latitude,
                                        longitude: longitude,
                                        type: response.type,
                                        date: dataDate,
                                        times: String(response.time),
                                        employeeId: String(response.employee_id),
                                        address: address)
            
            print("Modelo creado: \(newRecord)")
            do {
                 context.insert(newRecord)
                try context.save()
                await refreshRecord()
            } catch {
                print("Error al guardar el modelo en SwiftData: \(error.localizedDescription)")
            }
        }
    }
}
