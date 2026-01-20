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
    @StateObject private var errorManager = ErrorManager.shared
    
    private let appConfig = AppConfigurationManager.shared
    
    init() {
        // Initialize logging system
        logInfo("Initializing \(appConfig.current.appName)", category: .general, metadata: [
            "version": appConfig.versionNumber,
            "build": appConfig.buildNumber,
            "target": appConfig.current.appName
        ])
        
        // Configuración de SwiftData, UserManager, etc...
        do {
            let schema = Schema([
                UserModel.self,
                RecordModel.self
            ])
            
            // Delete existing store if migration fails
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            if FileManager.default.fileExists(atPath: storeURL.path) {
                do {
                    try FileManager.default.removeItem(at: storeURL)
                    logInfo("Removed existing data store for fresh migration", category: .database)
                } catch {
                    logWarning("Could not remove existing store: \(error)", category: .database)
                }
            }
            
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            UserManager.shared.configure(with: modelContainer.mainContext)
            // Ejecutar migraciones después de configurar UserManager
            UserManager.shared.runMigrations()
            
            RecordManager.shared.configure(with: modelContainer.mainContext)
            
            logInfo("SwiftData configuration completed successfully", category: .database)
        } catch {
            logCritical("Failed to configure SwiftData: \(error)", category: .database)
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
                .preferredColorScheme(.light)
                .environmentObject(notificationManager)
                .environmentObject(recordViewModel)
                .environmentObject(errorManager)
                .environmentObject(ThemeManager.shared)
                .errorAlert()
                .accentColor(ThemeManager.shared.currentTheme.primaryColor)
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                recordViewModel.checkIfNewDay()
            }
        }
    }
}
