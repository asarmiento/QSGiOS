import UIKit
import SwiftData
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import FirebaseAnalytics

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configura Firebase
        FirebaseApp.configure()
        
        // Configurar Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Configurar Messaging
        Messaging.messaging().delegate = self
        
        // Configurar notificaciones
        UNUserNotificationCenter.current().delegate = self
        
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

    // Agregar función para registrar pantallas en Analytics
    func logScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView,
                         parameters: [AnalyticsParameterScreenName: screenName,
                                    AnalyticsParameterScreenClass: screenClass])
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
        
        // Registrar evento de notificación recibida
        Analytics.logEvent("notification_received", parameters: [
            "type": userInfo["type"] as? String ?? "unknown",
            "background": UIApplication.shared.applicationState != .active
        ])
        
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

        // Verifica si se incluye el parámetro de evento
        if let event = userInfo["event"] as? String {
            // Registra el evento en Firebase Analytics
            Analytics.logEvent(event, parameters: [
                "category": userInfo["category"] as? String ?? "unknown"
            ])
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
