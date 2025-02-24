import UserNotifications
import SwiftUI

struct NotificationScheduler {
    
    /// Programa las notificaciones diarias que quieras (7:00 AM y 3:30 PM).
    static func scheduleDailyNotifications() {
        
        // Notificación #1 → a las 7:00 AM
        scheduleNotification(
            hour: 7,
            minute: 0,
            identifier: "morningNotification",
            title: "¡Buenos días!",
            body: "Este es un recordatorio para que marques el ingreso al trabajo."
        )
        
        // Notificación #2 → a las 3:30 PM
        scheduleNotification(
            hour: 15,
            minute: 30,
            identifier: "afternoonNotification",
            title: "¡Recordatorio de la tarde!",
            body: "Este es un recordatorio diario para que marques las salida del trabajo."
        )
    }
    
    /// Programar una notificación local repetitiva todos los días a una hora específica.
    private static func scheduleNotification(
        hour: Int,
        minute: Int,
        identifier: String,
        title: String,
        body: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound(named: UNNotificationSoundName("loudSound.wav"))
        
        // Configuramos la hora deseada
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Se repetirá todos los días (repeats = true) a la hora/minuto indicados
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error al programar notificación \(identifier): \(error.localizedDescription)")
            } else {
                print("Notificación \(identifier) programada satisfactoriamente.")
            }
        }
    }
} 
