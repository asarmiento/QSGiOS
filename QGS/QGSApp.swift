//
//  QGSApp.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//
import SwiftUI
import SwiftData
import FirebaseCore
import UserNotifications

@main
struct QGSApp: App {
    let modelContainer: ModelContainer
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    
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
            
            // Configurar UserManager con el contexto
            UserManager.shared.configure(with: modelContainer.mainContext)
            RecordManager.shared.configure(with: modelContainer.mainContext)
        } catch {
            fatalError("No se pudo configurar el contenedor SwiftData: \(error)")
        }

        // Solicitar permisos para notificaciones
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    NotificationScheduler.scheduleDailyNotifications()
                }
            } else {
                print("Permisos de notificaciones denegados: \(String(describing: error))")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
        }
        .modelContainer(modelContainer)
    }
}





