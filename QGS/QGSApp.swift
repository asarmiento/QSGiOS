//
//  QGSApp.swift
//  QGS
//
//  Created by Anwar Sarmiento on 7/24/24.
//
import SwiftUI
import SwiftData
import Firebase
import FirebaseCore
import UserNotifications

@main
struct QGSApp: App {
    let modelContainer: ModelContainer
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var recordViewModel = RecordViewModel()
    
    init() {
        // Configuración de SwiftData, UserManager, etc...
        do {
            let schema = Schema([
                UserModel.self,
                RecordModel.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            UserManager.shared.configure(with: modelContainer.mainContext)
            RecordManager.shared.configure(with: modelContainer.mainContext)
        } catch {
            fatalError("No se pudo configurar SwiftData: \(error)")
        }

        // Solicitar permiso para notificaciones
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    NotificationScheduler.scheduleWorkdaysNotifications()
                }
            } else {
                print("Permisos de notificaciones denegados: \(String(describing: error))")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .environmentObject(notificationManager)
                .environmentObject(recordViewModel)
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) {
            if $0 == .active {
                recordViewModel.checkIfNewDay()
            }
        }
    }
}
