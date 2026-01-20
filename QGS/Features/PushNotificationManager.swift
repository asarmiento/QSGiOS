import Foundation
import UserNotifications
import UIKit
import Firebase

// MARK: - Push Notification Manager
/// Comprehensive push notification system for QGS app
/// Handles registration, scheduling, and processing of notifications

class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()
    
    @Published var isAuthorized = false
    @Published var notificationSettings: UNNotificationSettings?
    @Published var deviceToken: String?
    
    private let center = UNUserNotificationCenter.current()
    private var pendingNotifications: [PendingNotification] = []
    
    // MARK: - Notification Categories
    enum NotificationCategory: String, CaseIterable {
        case timeReminder = "TIME_REMINDER"
        case projectUpdate = "PROJECT_UPDATE"
        case systemAlert = "SYSTEM_ALERT"
        case workSchedule = "WORK_SCHEDULE"
        
        var identifier: String {
            return self.rawValue
        }
        
        var actions: [UNNotificationAction] {
            switch self {
            case .timeReminder:
                return [
                    UNNotificationAction(
                        identifier: "RECORD_ENTRY",
                        title: "Registrar Entrada",
                        options: [.foreground]
                    ),
                    UNNotificationAction(
                        identifier: "RECORD_EXIT",
                        title: "Registrar Salida",
                        options: [.foreground]
                    ),
                    UNNotificationAction(
                        identifier: "SNOOZE_10",
                        title: "Recordar en 10 min",
                        options: []
                    )
                ]
            case .projectUpdate:
                return [
                    UNNotificationAction(
                        identifier: "VIEW_PROJECT",
                        title: "Ver Proyecto",
                        options: [.foreground]
                    ),
                    UNNotificationAction(
                        identifier: "DISMISS",
                        title: "Descartar",
                        options: [.destructive]
                    )
                ]
            case .systemAlert:
                return [
                    UNNotificationAction(
                        identifier: "OPEN_APP",
                        title: "Abrir App",
                        options: [.foreground]
                    )
                ]
            case .workSchedule:
                return [
                    UNNotificationAction(
                        identifier: "VIEW_SCHEDULE",
                        title: "Ver Horario",
                        options: [.foreground]
                    ),
                    UNNotificationAction(
                        identifier: "MARK_UNAVAILABLE",
                        title: "Marcar No Disponible",
                        options: []
                    )
                ]
            }
        }
    }
    
    // MARK: - Notification Types
    struct NotificationContent {
        let title: String
        let body: String
        let category: NotificationCategory
        let userInfo: [String: Any]
        let badge: Int?
        let sound: UNNotificationSound
        let attachments: [UNNotificationAttachment]
        
        init(
            title: String,
            body: String,
            category: NotificationCategory,
            userInfo: [String: Any] = [:],
            badge: Int? = nil,
            sound: UNNotificationSound = .default,
            attachments: [UNNotificationAttachment] = []
        ) {
            self.title = title
            self.body = body
            self.category = category
            self.userInfo = userInfo
            self.badge = badge
            self.sound = sound
            self.attachments = attachments
        }
    }
    
    private override init() {
        super.init()
        setupNotificationCenter()
        checkNotificationAuthorization()
        
        logInfo("PushNotificationManager initialized", category: .push)
    }
    
    // MARK: - Setup and Authorization
    
    private func setupNotificationCenter() {
        center.delegate = self
        
        // Register notification categories
        let categories = Set(NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.identifier,
                actions: category.actions,
                intentIdentifiers: [],
                options: []
            )
        })
        
        center.setNotificationCategories(categories)
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            
            await MainActor.run {
                isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
                logInfo("Push notification authorization granted", category: .push)
            } else {
                logWarning("Push notification authorization denied", category: .push)
            }
            
            return granted
        } catch {
            logError("Failed to request notification authorization", category: .push, metadata: [
                "error": error.localizedDescription
            ])
            return false
        }
    }
    
    private func checkNotificationAuthorization() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationSettings = settings
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    @MainActor
    private func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Device Token Management
    
    func didRegisterForRemoteNotifications(with deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        self.deviceToken = tokenString
        
        // Set APNs token for Firebase
        Messaging.messaging().apnsToken = deviceToken
        
        // Get FCM token
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                logError("Error fetching FCM registration token", category: .push, metadata: [
                    "error": error.localizedDescription
                ])
            } else if let token = token {
                logInfo("FCM registration token retrieved", category: .push, metadata: [
                    "token": token
                ])
                self?.sendTokenToServer(token)
            }
        }
        
        logInfo("Device token registered", category: .push, metadata: [
            "token": tokenString
        ])
    }
    
    func didFailToRegisterForRemoteNotifications(with error: Error) {
        logError("Failed to register for remote notifications", category: .push, metadata: [
            "error": error.localizedDescription
        ])
    }
    
    private func sendTokenToServer(_ token: String) {
        // Send FCM token to your server for targeting
        Task {
            do {
                let userID = SessionManager.shared.userId ?? "unknown"
                let config = RequestConfiguration(
                    endpoint: .registerNotificationToken,
                    method: .POST,
                    body: try JSONSerialization.data(withJSONObject: [
                        "user_id": userID,
                        "fcm_token": token,
                        "platform": "ios",
                        "app_version": AppConfigurationManager.shared.versionNumber,
                        "device_model": UIDevice.current.model,
                        "timestamp": Date().timeIntervalSince1970
                    ]),
                    requiresAuth: true
                )
                
                let _: EmptyResponse = try await SecureNetworkManager.shared.performRequest(config, responseType: EmptyResponse.self)
                
                logInfo("FCM token sent to server successfully", category: .push)
            } catch {
                logError("Failed to send FCM token to server", category: .push, metadata: [
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(
        identifier: String,
        content: NotificationContent,
        trigger: UNNotificationTrigger
    ) async throws {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: buildNotificationContent(content),
            trigger: trigger
        )
        
        try await center.add(request)
        
        logInfo("Local notification scheduled", category: .push, metadata: [
            "identifier": identifier,
            "category": content.category.rawValue
        ])
    }
    
    private func buildNotificationContent(_ content: NotificationContent) -> UNMutableNotificationContent {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.body = content.body
        notificationContent.categoryIdentifier = content.category.identifier
        notificationContent.userInfo = content.userInfo
        notificationContent.sound = content.sound
        notificationContent.attachments = content.attachments
        
        if let badge = content.badge {
            notificationContent.badge = NSNumber(value: badge)
        }
        
        return notificationContent
    }
    
    // MARK: - Work Schedule Notifications
    
    func scheduleWorkReminders() async {
        // Clear existing work reminders
        await cancelNotifications(withIdentifiers: ["work_start_reminder", "work_end_reminder"])
        
        guard isAuthorized else {
            logWarning("Cannot schedule work reminders - not authorized", category: .push)
            return
        }
        
        // Schedule work start reminder (8:00 AM Monday-Friday)
        let startReminderContent = NotificationContent(
            title: "¡Hora de trabajar! 💼",
            body: "Es hora de registrar tu entrada. ¿Ya llegaste al trabajo?",
            category: .timeReminder,
            userInfo: ["type": "work_start"],
            badge: 1
        )
        
        var startDateComponents = DateComponents()
        startDateComponents.hour = 8
        startDateComponents.minute = 0
        startDateComponents.weekday = 2 // Monday
        
        let startTrigger = UNCalendarNotificationTrigger(
            dateMatching: startDateComponents,
            repeats: true
        )
        
        try? await scheduleLocalNotification(
            identifier: "work_start_reminder",
            content: startReminderContent,
            trigger: startTrigger
        )
        
        // Schedule work end reminder (5:00 PM Monday-Friday)
        let endReminderContent = NotificationContent(
            title: "Fin del día laboral 🏠",
            body: "¿Ya terminaste tu jornada? No olvides registrar tu salida.",
            category: .timeReminder,
            userInfo: ["type": "work_end"],
            badge: 1
        )
        
        var endDateComponents = DateComponents()
        endDateComponents.hour = 17
        endDateComponents.minute = 0
        endDateComponents.weekday = 2 // Monday
        
        let endTrigger = UNCalendarNotificationTrigger(
            dateMatching: endDateComponents,
            repeats: true
        )
        
        try? await scheduleLocalNotification(
            identifier: "work_end_reminder",
            content: endReminderContent,
            trigger: endTrigger
        )
        
        logInfo("Work reminder notifications scheduled", category: .push)
    }
    
    // MARK: - Break Reminders
    
    func scheduleBreakReminder(after timeInterval: TimeInterval) async {
        let content = NotificationContent(
            title: "Tiempo de descanso ☕️",
            body: "Has estado trabajando por un tiempo. ¿Qué tal un pequeño descanso?",
            category: .timeReminder,
            userInfo: ["type": "break_reminder"]
        )
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        try? await scheduleLocalNotification(
            identifier: "break_reminder_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
    }
    
    // MARK: - Project Notifications
    
    func notifyProjectUpdate(projectName: String, message: String) async {
        let content = NotificationContent(
            title: "Actualización de Proyecto",
            body: "\(projectName): \(message)",
            category: .projectUpdate,
            userInfo: [
                "type": "project_update",
                "project_name": projectName
            ]
        )
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        try? await scheduleLocalNotification(
            identifier: "project_update_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
    }
    
    // MARK: - System Notifications
    
    func notifySystemAlert(title: String, message: String, isUrgent: Bool = false) async {
        let content = NotificationContent(
            title: title,
            body: message,
            category: .systemAlert,
            userInfo: [
                "type": "system_alert",
                "urgent": isUrgent
            ],
            sound: isUrgent ? .defaultCritical : .default
        )
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        try? await scheduleLocalNotification(
            identifier: "system_alert_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
    }
    
    // MARK: - Notification Management
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }
    
    func cancelNotifications(withIdentifiers identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        
        logInfo("Notifications cancelled", category: .push, metadata: [
            "identifiers": identifiers.joined(separator: ", ")
        ])
    }
    
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        logInfo("All notifications cancelled", category: .push)
    }
    
    func updateBadgeCount(_ count: Int) {
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    // MARK: - Smart Notification Logic
    
    func scheduleSmartReminders() async {
        guard isAuthorized else { return }
        
        // Get user's work pattern from records
        let workPattern = await analyzeWorkPattern()
        
        // Schedule personalized reminders based on work pattern
        if let pattern = workPattern {
            await schedulePersonalizedReminders(pattern: pattern)
        } else {
            // Fallback to default schedule
            await scheduleWorkReminders()
        }
    }
    
    private func analyzeWorkPattern() async -> WorkPattern? {
        // Analyze user's historical time records to determine typical work schedule
        // This would integrate with your time records data
        
        // Placeholder implementation
        return WorkPattern(
            startTime: (hour: 8, minute: 0),
            endTime: (hour: 17, minute: 0),
            workDays: [2, 3, 4, 5, 6], // Monday to Friday
            breakTimes: [(hour: 12, minute: 0), (hour: 15, minute: 0)]
        )
    }
    
    private func schedulePersonalizedReminders(pattern: WorkPattern) async {
        // Schedule start reminder 15 minutes before typical start time
        if let startTrigger = createWeeklyTrigger(
            hour: pattern.startTime.hour,
            minute: max(0, pattern.startTime.minute - 15),
            weekdays: pattern.workDays
        ) {
            let content = NotificationContent(
                title: "Preparándote para trabajar 🌅",
                body: "Tu horario usual de entrada es pronto. ¿Ya estás listo?",
                category: .timeReminder,
                userInfo: ["type": "personalized_start"]
            )
            
            try? await scheduleLocalNotification(
                identifier: "personalized_start_reminder",
                content: content,
                trigger: startTrigger
            )
        }
        
        // Schedule end reminder at typical end time
        if let endTrigger = createWeeklyTrigger(
            hour: pattern.endTime.hour,
            minute: pattern.endTime.minute,
            weekdays: pattern.workDays
        ) {
            let content = NotificationContent(
                title: "Fin de jornada 🎉",
                body: "Según tu horario usual, es hora de terminar. ¡Buen trabajo hoy!",
                category: .timeReminder,
                userInfo: ["type": "personalized_end"]
            )
            
            try? await scheduleLocalNotification(
                identifier: "personalized_end_reminder",
                content: content,
                trigger: endTrigger
            )
        }
    }
    
    private func createWeeklyTrigger(hour: Int, minute: Int, weekdays: [Int]) -> UNNotificationTrigger? {
        // Create a calendar trigger for specific weekdays
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = weekdays.first // Simplified - would need multiple triggers for all weekdays
        
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        logInfo("Notification received in foreground", category: .push, metadata: [
            "identifier": notification.request.identifier,
            "category": notification.request.content.categoryIdentifier
        ])
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        logInfo("Notification action received", category: .push, metadata: [
            "action": actionIdentifier,
            "userInfo": userInfo.description
        ])
        
        Task {
            await handleNotificationAction(actionIdentifier: actionIdentifier, userInfo: userInfo)
            completionHandler()
        }
    }
    
    private func handleNotificationAction(actionIdentifier: String, userInfo: [AnyHashable: Any]) async {
        switch actionIdentifier {
        case "RECORD_ENTRY":
            NotificationCenter.default.post(name: .recordEntryFromNotification, object: userInfo)
            
        case "RECORD_EXIT":
            NotificationCenter.default.post(name: .recordExitFromNotification, object: userInfo)
            
        case "SNOOZE_10":
            // Schedule snooze notification
            let content = NotificationContent(
                title: "Recordatorio de Registro ⏰",
                body: "¿Ya registraste tu hora de trabajo?",
                category: .timeReminder,
                userInfo: userInfo as? [String: Any] ?? [:]
            )
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 600, repeats: false) // 10 minutes
            
            try? await scheduleLocalNotification(
                identifier: "snooze_reminder_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
        case "VIEW_PROJECT":
            if let projectName = userInfo["project_name"] as? String {
                NotificationCenter.default.post(name: .viewProjectFromNotification, object: projectName)
            }
            
        case "VIEW_SCHEDULE":
            NotificationCenter.default.post(name: .viewScheduleFromNotification, object: nil)
            
        case "OPEN_APP":
            // App is already opening, no additional action needed
            break
            
        default:
            break
        }
        
        // Update badge count
        let deliveredNotifications = await getDeliveredNotifications()
        updateBadgeCount(deliveredNotifications.count)
    }
}

// MARK: - Supporting Types

struct WorkPattern {
    let startTime: (hour: Int, minute: Int)
    let endTime: (hour: Int, minute: Int)
    let workDays: [Int] // 1=Sunday, 2=Monday, etc.
    let breakTimes: [(hour: Int, minute: Int)]
}

struct PendingNotification {
    let identifier: String
    let category: PushNotificationManager.NotificationCategory
    let scheduledDate: Date
    let userInfo: [String: Any]
}

// MARK: - Notification Names
extension Notification.Name {
    static let recordEntryFromNotification = Notification.Name("recordEntryFromNotification")
    static let recordExitFromNotification = Notification.Name("recordExitFromNotification")
    static let viewProjectFromNotification = Notification.Name("viewProjectFromNotification")
    static let viewScheduleFromNotification = Notification.Name("viewScheduleFromNotification")
}

