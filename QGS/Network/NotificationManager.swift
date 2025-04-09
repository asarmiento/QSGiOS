//
//  NotificationManager.swift
//  QGS
//
//  Created by Edin Martinez on 3/7/25.
//
import Foundation
import FirebaseCore
import FirebaseMessaging
import FirebaseFirestore

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var fcmToken: String?
 
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    print("Notificaciones autorizadas")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else if let error = error {
                    print("Error al solicitar autorización para notificaciones: \(error.localizedDescription)")
                }
            }
        )
    }
    private var employeeId: String? {
        
        return UserManager.shared.getEmployeeId
    }
    
    func saveTokenToFirestore(token: String) {
        // Verificar que el usuario esté autenticado
        guard let userId = employeeId else {
            print("No hay usuario autenticado para guardar el token FCM")
            return
        }
        
        // Guardar el token en Firestore
        let db = Firestore.firestore()
        db.collection("users").document(userId).setData([
            "fcmToken": token,
            "lastUpdated": Date().timeIntervalSince1970
        ], merge: true) { error in
            if let error = error {
                print("Error al guardar el token FCM: \(error.localizedDescription)")
            } else {
                print("Token FCM guardado correctamente para el usuario \(userId)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Mostrar notificación incluso si la app está en primer plano
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Manejar la interacción del usuario con la notificación
        let userInfo = response.notification.request.content.userInfo
        print("Notificación recibida: \(userInfo)")
        
        // Aquí puedes implementar la lógica para manejar diferentes tipos de notificaciones
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Token FCM: \(token)")
            self.fcmToken = token
            
            // Guardar el token en Firestore solo si hay un usuario autenticado
            if employeeId != nil {
                saveTokenToFirestore(token: token)
            }
        }
    }
}
