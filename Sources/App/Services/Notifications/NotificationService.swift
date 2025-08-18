import Foundation
import UserNotifications

/// Service for managing local notifications
class NotificationService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        
        await MainActor.run {
            isAuthorized = granted
        }
        
        if granted {
            center.delegate = self
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Session Notifications
    
    func scheduleSessionWarning(appName: String, timeRemaining: TimeInterval) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Session Ending Soon"
        content.body = "\(appName) session ends in \(Int(timeRemaining/60)) minutes"
        content.sound = .default
        content.categoryIdentifier = "SESSION_WARNING"
        
        // Add grace time action for Pro users
        let graceAction = UNNotificationAction(
            identifier: "ADD_GRACE_TIME",
            title: "Add 2 minutes",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "SESSION_WARNING",
            actions: [graceAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "session_warning_\(appName)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleSessionEnd(appName: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Session Complete"
        content.body = "Your \(appName) session has ended"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "session_end_\(appName)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleStreakCelebration(streakCount: Int) {
        guard isAuthorized, streakCount > 1 else { return }
        
        let content = UNMutableNotificationContent()
        
        switch streakCount {
        case 3:
            content.title = "🔥 3-Day Streak!"
            content.body = "You're building great habits with intentional screen time."
        case 7:
            content.title = "🌟 One Week Strong!"
            content.body = "A full week of mindful app usage. Keep it up!"
        case 30:
            content.title = "🏆 30-Day Champion!"
            content.body = "A full month of intentional screen time. You're amazing!"
        case _ where streakCount % 10 == 0:
            content.title = "🎉 \(streakCount)-Day Streak!"
            content.body = "Your consistency with intentional usage is inspiring."
        default:
            return // Don't notify for other numbers
        }
        
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_celebration_\(streakCount)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Daily Reminders
    
    func scheduleDailyReflection() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Reflection"
        content.body = "How did your intentional screen time go today?"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 21 // 9 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reflection",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Utility
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier
        let notificationIdentifier = response.notification.request.identifier
        
        switch identifier {
        case "ADD_GRACE_TIME":
            handleGraceTimeAction(notificationIdentifier: notificationIdentifier)
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            handleDefaultAction(notificationIdentifier: notificationIdentifier)
        default:
            break
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    private func handleGraceTimeAction(notificationIdentifier: String) {
        // Extract app name from identifier
        let components = notificationIdentifier.components(separatedBy: "_")
        guard components.count >= 3 else { return }
        
        let appName = components.suffix(from: 2).joined(separator: "_")
        
        // Post notification for the main app to handle
        NotificationCenter.default.post(
            name: NSNotification.Name("GraceTimeRequested"),
            object: appName
        )
    }
    
    private func handleDefaultAction(notificationIdentifier: String) {
        // Handle default notification tap
        if notificationIdentifier.hasPrefix("session_end_") {
            // User tapped session end notification - could open session log
            NotificationCenter.default.post(
                name: NSNotification.Name("SessionEndNotificationTapped"),
                object: notificationIdentifier
            )
        }
    }
}

// MARK: - Notification Categories

extension NotificationService {
    static func registerNotificationCategories() {
        let graceAction = UNNotificationAction(
            identifier: "ADD_GRACE_TIME",
            title: "Add 2 minutes",
            options: []
        )
        
        let sessionWarningCategory = UNNotificationCategory(
            identifier: "SESSION_WARNING",
            actions: [graceAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([sessionWarningCategory])
    }
}