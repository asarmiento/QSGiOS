import UIKit
import SwiftData
import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAnalytics
import AppTrackingTransparency

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configura Firebase
        FirebaseApp.configure()
        
        // Desactivar completamente Analytics
        Analytics.setAnalyticsCollectionEnabled(false)
        
        // Desactivar el seguimiento de usuarios
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                // No hacemos nada con el resultado, solo cumplimos con el requisito
            }
        }
        
        // Configurar Messaging
        Messaging.messaging().delegate = self
        
        // Configurar notificaciones
        UNUserNotificationCenter.current().delegate = self
        
        // Configura App Check
         // AppCheck.appCheck()
        
            
        
        // Solicitar permisos para notificaciones
        requestNotificationPermissions()
        
        // Registra para recibir notificaciones remotas
        application.registerForRemoteNotifications()
        
        // Imprimir estado actual
        if let token = Messaging.messaging().fcmToken {
            print("✅ Token FCM existente: \(token)")
        } else {
            print("⏳ Esperando token FCM...")
        }
        
        return true
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

    // Reemplazar la función de Analytics con una versión vacía
    func logScreenView(screenName: String, screenClass: String) {
        // No hacemos nada, para evitar el seguimiento
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
}

// MARK: - UIApplicationDelegate Methods
extension AppDelegate {
    @objc func application(_ application: UIApplication,
                          didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNs token recibido")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNs token: \(token)")
        
        // Registra el token con Firebase
        Messaging.messaging().apnsToken = deviceToken
        
        // Obtén el token de FCM
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
        
        // Eliminar el registro de eventos de Analytics
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
            
            // Guarda el token localmente si lo necesitas
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
        // Maneja la notificación cuando el usuario la toca
        let userInfo = response.notification.request.content.userInfo
        print("Notificación recibida: \(userInfo)")

        // Eliminar el registro de eventos en Analytics
        if let event = userInfo["event"] as? String {
            print("Evento de notificación recibido: \(event)")
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Muestra la notificación mientras la app está en primer plano
        completionHandler([.banner, .badge, .sound])
    }
}
