import DeviceActivity
import Foundation

class DeviceActivityMonitor: DeviceActivityMonitor {
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // This is called when a device activity interval starts
        // In our case, we use this to track when apps are opened
        
        // Post notification to app group for coordination
        let center = NotificationCenter.default
        center.post(name: NSNotification.Name("DeviceActivityIntervalStarted"), object: activity.rawValue)
        
        // Update shared storage
        updateActivityLog(activity: activity, event: "intervalStarted")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // This is called when a device activity interval ends
        // We use this to handle session timeouts and re-enable shields
        
        let center = NotificationCenter.default
        center.post(name: NSNotification.Name("DeviceActivityIntervalEnded"), object: activity.rawValue)
        
        updateActivityLog(activity: activity, event: "intervalEnded")
        
        // Handle session end logic
        handleSessionEnd(for: activity)
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // This is called when usage thresholds are reached
        // We can use this for warnings and grace period handling
        
        let center = NotificationCenter.default
        center.post(name: NSNotification.Name("DeviceActivityThresholdReached"), object: [
            "event": event.rawValue,
            "activity": activity.rawValue
        ])
        
        updateActivityLog(activity: activity, event: "thresholdReached", details: event.rawValue)
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Called before interval starts - can be used for warnings
        updateActivityLog(activity: activity, event: "intervalWillStartWarning")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Called before interval ends - can be used for warnings
        updateActivityLog(activity: activity, event: "intervalWillEndWarning")
        
        // This is where we might show the "2 minutes remaining" notification
        scheduleSessionEndingWarning(for: activity)
    }
    
    // MARK: - Private Methods
    
    private func updateActivityLog(activity: DeviceActivityName, event: String, details: String? = nil) {
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        
        let logEntry: [String: Any] = [
            "activity": activity.rawValue,
            "event": event,
            "details": details ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        var existingLogs = defaults?.object(forKey: "deviceActivityLogs") as? [[String: Any]] ?? []
        existingLogs.append(logEntry)
        
        // Keep only last 100 entries
        if existingLogs.count > 100 {
            existingLogs = Array(existingLogs.suffix(100))
        }
        
        defaults?.set(existingLogs, forKey: "deviceActivityLogs")
    }
    
    private func handleSessionEnd(for activity: DeviceActivityName) {
        // Extract app ID from activity name
        let appId = activity.rawValue
        
        // Update session end in shared storage
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        
        var activeSessions = defaults?.object(forKey: "activeSessionsV2") as? [String: [String: Any]] ?? [:]
        
        if var sessionData = activeSessions[appId] {
            sessionData["endedBySystem"] = true
            sessionData["actualEndTime"] = Date().timeIntervalSince1970
            activeSessions[appId] = sessionData
            
            defaults?.set(activeSessions, forKey: "activeSessionsV2")
        }
        
        // The main app will pick up this change and handle UI updates
    }
    
    private func scheduleSessionEndingWarning(for activity: DeviceActivityName) {
        // Schedule a local notification warning that session is ending soon
        let content = UNMutableNotificationContent()
        content.title = "Session Ending Soon"
        content.body = "Your session will end in 2 minutes. Wrap up what you're doing."
        content.sound = .default
        
        // Add action for grace time (if Pro)
        let graceAction = UNNotificationAction(
            identifier: "GRACE_ACTION",
            title: "Add 2 minutes",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "SESSION_WARNING",
            actions: [graceAction],
            intentIdentifiers: [],
            options: []
        )
        
        content.categoryIdentifier = "SESSION_WARNING"
        content.userInfo = ["activityName": activity.rawValue]
        
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "session_warning_\(activity.rawValue)", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule warning notification: \(error)")
            }
        }
    }
}

// MARK: - Notification Names Extension

extension NSNotification.Name {
    static let deviceActivityIntervalStarted = NSNotification.Name("DeviceActivityIntervalStarted")
    static let deviceActivityIntervalEnded = NSNotification.Name("DeviceActivityIntervalEnded") 
    static let deviceActivityThresholdReached = NSNotification.Name("DeviceActivityThresholdReached")
}