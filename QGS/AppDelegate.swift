import UIKit
import SwiftData
import Firebase
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics
import FirebaseFirestore    // <-- Import necesario para Firestore
//import FirebaseFirestoreSwift // Opcional si decodificas con Codable
import UserNotifications
import AppTrackingTransparency
import FirebaseAppCheck  // Asegurarse de que esto esté importado
import Photos
import Foundation
import Security

// Eliminamos la referencia directa al KeychainManager que causa problemas
// private let keychainManager = KeychainManager.shared

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // Necesitas 'import FirebaseFirestore' para reconocer ListenerRegistration
    var listener: ListenerRegistration?
    
    // Variable estática para compartir el último mensaje en la app
    static var lastMessage: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configura Firebase
        FirebaseApp.configure()
        
        // Configurar AppCheck para mejorar la seguridad
        #if DEBUG
        // En entorno de desarrollo, usar proveedor de depuración
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        // En producción, usar providerFactory basado en DeviceCheck
        let providerFactory = DeviceCheckProviderFactory()
        #endif
        
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Desactivar Analytics si lo deseas
        Analytics.setAnalyticsCollectionEnabled(false)
        
        // Verificar la integridad de la sesión
        verifyUserSession()
        
        // Solicitar tracking
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                // No hacemos nada especial
            }
        }
        
        // Configurar delegado de mensajería
        Messaging.messaging().delegate = self
        
        // Configurar UserNotificationCenter
        UNUserNotificationCenter.current().delegate = self
        
        // Si el usuario está logueado, inicia escucha de Firestore
        if let employeeId = UserManager.shared.getEmployeeId {
            startListeningForMessages(employeeId: employeeId)
        }
        
        // Solicitar permiso para notificaciones
        requestNotificationPermissions()
        
        // Registrar APNs
        application.registerForRemoteNotifications()
        
        if let token = Messaging.messaging().fcmToken {
            print("✅ Token FCM existente: \(token)")
        } else {
            print("⏳ Esperando token FCM...")
        }
        
        return true
    }
    
    // MARK: - Escucha de Firestore
    func startListeningForMessages(employeeId: String) {
        let db = Firestore.firestore() // <-- Usa Firestore
        // Escucha en la subcolección "recipients" de todos los documentos
        // Ajusta la ruta según tu estructura
        listener = db.collectionGroup("messages")
            .whereField("senderId", isEqualTo: employeeId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error escuchando recipients: \(error)")
                    return
                }
                guard let snapshot = querySnapshot else { return }
                
                for change in snapshot.documentChanges where change.type == .added {
                    let data = change.document.data()
                    let message = data["message"] as? String ?? "Mensaje sin texto"
                    let senderId = data["senderId"] as? String ?? "Desconocido"
                    
                    // Evitar notificar si es el mismo user
                    if senderId != employeeId {
                        AppDelegate.lastMessage = message
                        
                        // Opcional: Notificación interna
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NewMessageReceived"),
                            object: nil,
                            userInfo: ["message": message]
                        )
                        
                        // Opcional: Notificación local si está en segundo plano
                        // DispatchQueue.main.async {
                        //     self.showLocalNotification(message: message)
                        // }
                    }
                }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Notificación local inmediata
    func showLocalNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Nuevo Mensaje"
        content.body = message
        content.sound = .default
        
        // 'nil' requiere tipo explícito o un trigger real
        let trigger: UNNotificationTrigger? = nil // Noti inmediata
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permisos de notificación concedidos")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("❌ Error al solicitar permisos de notificación: \(error.localizedDescription)")
            } else {
                print("❌ Permisos de notificación denegados")
            }
        }
    }
    
    // MARK: - Desactivar Analytics manualmente (si lo deseas)
    func logScreenView(screenName: String, screenClass: String) {
        print("Intento de registro de pantalla ignorado: \(screenName)")
    }
    
    func refreshFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error al obtener token FCM: \(error.localizedDescription)")
            } else if let token = token {
                print("✅ Token FCM actualizado: \(token)")
            }
        }
    }
    
    // Función para verificar la integridad de la sesión
    private func verifyUserSession() {
        let userManager = UserManager.shared
        
        // Usar UserDefaults para verificación básica
        let defaults = UserDefaults.standard
        if let token = defaults.string(forKey: "authToken"), !token.isEmpty {
            print("✅ Token encontrado en UserDefaults: \(token.prefix(10))...")
            
            // Verificar que tengamos los datos básicos del usuario
            if userManager.getUserType == nil || userManager.getEmployeeId == nil {
                print("⚠️ Sesión parcialmente corrupta: token presente pero faltan datos de usuario")
            }
        } else {
            print("⚠️ No se encontró token en UserDefaults")
            
            // Intentar restaurar token desde UserManager si está disponible
            if let token = userManager.getAuthToken, !token.isEmpty {
                defaults.set(token, forKey: "authToken")
                defaults.synchronize()
                print("✅ Token restaurado desde UserManager a UserDefaults")
            }
        }
    }
}

// MARK: - UIApplicationDelegate Methods
extension AppDelegate {
    @objc func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNs token recibido")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNs token: \(token)")
        
        // Vincular APNs token con Firebase
        Messaging.messaging().apnsToken = deviceToken
        
        // Intentar obtener token FCM
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error al obtener token FCM: \(error.localizedDescription)")
            } else if let token = token {
                print("✅ Token FCM: \(token)")
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Error al registrar para notificaciones remotas: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("Notificación recibida en estado: \(UIApplication.shared.applicationState != .active ? "background" : "foreground")")
        completionHandler(.newData)
    }
}

// MARK: - Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("➡️ Firebase Registration Token:")
        if let token = fcmToken {
            print("✅ Token FCM recibido: \(token)")
            
            // Guarda token local si lo necesitas
            UserDefaults.standard.set(token, forKey: "FCMToken")
            
            // Notifica a la app que el token fue actualizado
            NotificationCenter.default.post(
                name: Notification.Name("FCMToken"),
                object: nil,
                userInfo: ["token": token]
            )
        } else {
            print("❌ No se recibió el token de Firebase")
            print("Estado de configuración:")
            print("- Firebase configurado: \(FirebaseApp.app() != nil)")
            print("- APNs token: \(String(describing: Messaging.messaging().apnsToken))")
        }
    }
}

// MARK: - UNUserNotificationCenter Delegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Notificación recibida: \(userInfo)")
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .badge, .sound])
    }
}
