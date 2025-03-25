import UserNotifications
import SwiftUI

struct NotificationScheduler {
    
    /// Programa las notificaciones de lunes a viernes:
    /// - 7:00 AM (entrada)
    /// - 3:30 PM (salida)
    static func scheduleWorkdaysNotifications() {
        // Notificación de la mañana (lunes a viernes)
        scheduleWorkdaysNotification(
            hour: 7,
            minute: 0,
            identifierPrefix: "morningNotification",
            title: "¡Buenos días!",
            body: "Recuerda registrar tu hora de entrada."
        )
        
        // Notificación de la tarde (lunes a viernes)
        scheduleWorkdaysNotification(
            hour: 15,
            minute: 30,
            identifierPrefix: "afternoonNotification",
            title: "¡Recordatorio de la tarde!",
            body: "Recuerda registrar tu hora de salida."
        )
    }
    
    /// Programa una notificación para cada día de la semana laboral (lunes=2 a viernes=6).
    private static func scheduleWorkdaysNotification(
        hour: Int,
        minute: Int,
        identifierPrefix: String,
        title: String,
        body: String
    ) {
        // Lunes=2, martes=3, miércoles=4, jueves=5, viernes=6 en el Calendar de iOS
        for weekday in 2...6 {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound(named: UNNotificationSoundName("loudSound.wav"))
            
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            dateComponents.weekday = weekday    // 2..6 → Lunes..Viernes
            dateComponents.hour = hour
            dateComponents.minute = minute
            
            // repeats = true, pero se activará únicamente el día y hora especificados
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Cada día tendrá un identificador distinto, por ejemplo: "morningNotification-2", "morningNotification-3", ...
            let identifier = "\(identifierPrefix)-\(weekday)"
            
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error al programar notificación \(identifier): \(error.localizedDescription)")
                } else {
                    print("Notificación \(identifier) programada para weekday=\(weekday) satisfactoriamente.")
                }
            }
        }
    }
}
