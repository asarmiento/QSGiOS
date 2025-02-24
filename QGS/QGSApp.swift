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
        } catch {
            fatalError("Could not configure SwiftData container: \(error)")
        }

        // (1) Pedimos permisos de notificaciones (si no lo haces en AppDelegate)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    // (2) Programamos las notificaciones cuando tengamos permisos
                    NotificationScheduler.scheduleDailyNotifications()
                }
            } else {
                print("Permisos de notificaciones denegados o error: \(String(describing: error))")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            // Fondo y diseño general
            
            SplashView()
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }
}






