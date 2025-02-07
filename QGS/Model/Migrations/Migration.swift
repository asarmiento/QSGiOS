import SwiftData

struct Migration {
    static func migrate(from oldVersion: Int, to newVersion: Int, context: ModelContext) {
        if oldVersion < 1 {
            // Lógica para migrar de la versión 0 a la versión 1
        }
        if oldVersion < 2 {
            // Lógica para migrar de la versión 1 a la versión 2
            do {
                let records = try context.fetch(FetchDescriptor<RecordModel>())
                for record in records {
                    record.message = "Default Message" // Puedes asignar un valor por defecto
                }
                try context.save()
                print("Migración a la versión 2 completada correctamente.")
            } catch {
                print("Error en la migración a la versión 2: \(error)")
            }
        }
        // Agrega más condiciones según sea necesario
    }
} 
