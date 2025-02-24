//
//  QGSApp.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//
import SwiftUI
import SwiftData
import FirebaseCore

@main
struct QGSApp: App {
    let modelContainer: ModelContainer
    
    init() {
        
        do {
            // Configurar el esquema
            let schema = Schema([
                UserModel.self,
                RecordModel.self
            ])
            
            // Configurar el contenedor
            let modelConfiguration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not configure SwiftData container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // Fondo y diseño general
            
            SplashView()
        }
        .modelContainer(modelContainer)
    }
}






