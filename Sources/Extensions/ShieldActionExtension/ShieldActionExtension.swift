import ManagedSettings
import Foundation

class ShieldActionExtension: ShieldActionExtension {
    
    override func handle(action: ShieldAction, for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        switch action {
        case .primaryButtonPressed:
            handlePrimaryButtonPressed(for: application, completionHandler: completionHandler)
            
        case .secondaryButtonPressed:
            handleSecondaryButtonPressed(completionHandler: completionHandler)
            
        @unknown default:
            completionHandler(.defer)
        }
    }
    
    override func handle(action: ShieldAction, for applicationCategory: ApplicationCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        switch action {
        case .primaryButtonPressed:
            handlePrimaryButtonPressed(for: applicationCategory, completionHandler: completionHandler)
            
        case .secondaryButtonPressed:
            handleSecondaryButtonPressed(completionHandler: completionHandler)
            
        @unknown default:
            completionHandler(.defer)
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        
        switch action {
        case .primaryButtonPressed:
            handlePrimaryButtonPressed(for: webDomain, completionHandler: completionHandler)
            
        case .secondaryButtonPressed:
            handleSecondaryButtonPressed(completionHandler: completionHandler)
            
        @unknown default:
            completionHandler(.defer)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handlePrimaryButtonPressed(for application: Application, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        
        // Find the app quota for this application
        guard let appQuota = findAppQuota(for: application, in: defaults) else {
            // If no quota found, defer to system
            completionHandler(.defer)
            return
        }
        
        // Check if user can start a new session
        let usage = getDailyUsage(for: appQuota.id, in: defaults)
        
        if usage.sessionsUsed >= appQuota.sessionsPerDay {
            // Daily limit reached, keep shield active
            logShieldAction("primary_button_pressed_limit_reached", appId: appQuota.id)
            completionHandler(.defer)
            return
        }
        
        // Start a new session
        if startSession(for: appQuota, in: defaults) {
            logShieldAction("session_started_via_shield", appId: appQuota.id)
            
            // Allow access by closing the shield
            completionHandler(.close)
        } else {
            // Failed to start session
            logShieldAction("session_start_failed", appId: appQuota.id)
            completionHandler(.defer)
        }
    }
    
    private func handlePrimaryButtonPressed(for applicationCategory: ApplicationCategory, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Similar logic for categories
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        
        if let categoryQuota = findCategoryQuota(for: applicationCategory, in: defaults) {
            let usage = getDailyUsage(for: categoryQuota.id, in: defaults)
            
            if usage.sessionsUsed >= categoryQuota.sessionsPerDay {
                completionHandler(.defer)
                return
            }
            
            if startSession(for: categoryQuota, in: defaults) {
                completionHandler(.close)
            } else {
                completionHandler(.defer)
            }
        } else {
            completionHandler(.defer)
        }
    }
    
    private func handlePrimaryButtonPressed(for webDomain: WebDomain, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle web domain shield action
        logShieldAction("web_domain_primary_pressed", appId: webDomain.domain)
        completionHandler(.close)
    }
    
    private func handleSecondaryButtonPressed(completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // User chose "Not Now" - keep the shield active
        logShieldAction("secondary_button_pressed", appId: "unknown")
        completionHandler(.defer)
    }
    
    // MARK: - Helper Methods
    
    private func findAppQuota(for application: Application, in defaults: UserDefaults?) -> AppQuotaData? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: "appQuotas") else {
            return nil
        }
        
        do {
            let quotas = try JSONDecoder().decode([AppQuotaData].self, from: data)
            return quotas.first { quota in
                // Match app by display name - in production, you'd use better matching
                // Match app by stable identifier (e.g., bundleIdentifier or token)
                quota.bundleIdentifier == application.bundleIdentifier
            }
        } catch {
            return nil
        }
    }
    
    private func findCategoryQuota(for category: ApplicationCategory, in defaults: UserDefaults?) -> AppQuotaData? {
        guard let defaults = defaults,
              let data = defaults.data(forKey: "appQuotas") else {
            return nil
        }
        
        do {
            let quotas = try JSONDecoder().decode([AppQuotaData].self, from: data)
            return quotas.first { quota in
                // Match category quotas
                quota.displayName.contains("Category")
            }
        } catch {
            return nil
        }
    }
    
    private func getDailyUsage(for appId: String, in defaults: UserDefaults?) -> DailyUsageData {
        guard let defaults = defaults,
              let data = defaults.data(forKey: "dailyUsage") else {
            return DailyUsageData(appId: appId, dateKey: todayKey(), sessionsUsed: 0)
        }
        
        do {
            let usageDict = try JSONDecoder().decode([String: DailyUsageData].self, from: data)
            return usageDict[appId] ?? DailyUsageData(appId: appId, dateKey: todayKey(), sessionsUsed: 0)
        } catch {
            return DailyUsageData(appId: appId, dateKey: todayKey(), sessionsUsed: 0)
        }
    }
    
    private func startSession(for quota: AppQuotaData, in defaults: UserDefaults?) -> Bool {
        guard let defaults = defaults else { return false }
        
        let sessionId = UUID().uuidString
        let now = Date()
        let duration = TimeInterval(quota.sessionMinutes * 60)
        let endTime = now.addingTimeInterval(duration)
        
        // Create session data
        let sessionData: [String: Any] = [
            "appId": quota.id,
            "startTime": now.timeIntervalSince1970,
            "duration": duration,
            "hasGrace": false,
            "sessionId": sessionId
        ]
        
        // Update active sessions
        var activeSessions = defaults.object(forKey: "activeSessionsV2") as? [String: [String: Any]] ?? [:]
        activeSessions[quota.id] = sessionData
        defaults.set(activeSessions, forKey: "activeSessionsV2")
        
        // Update daily usage
        var dailyUsage = getDailyUsageDict(from: defaults)
        var usage = dailyUsage[quota.id] ?? DailyUsageData(appId: quota.id, dateKey: todayKey(), sessionsUsed: 0)
        usage.sessionsUsed += 1
        dailyUsage[quota.id] = usage
        
        // Save updated usage
        do {
            let data = try JSONEncoder().encode(dailyUsage)
            defaults.set(data, forKey: "dailyUsage")
        } catch {
            return false
        }
        
        // Schedule session end notification to main app
        scheduleSessionEndNotification(for: quota.id, at: endTime)
        
        return true
    }
    
    private func getDailyUsageDict(from defaults: UserDefaults) -> [String: DailyUsageData] {
        guard let data = defaults.data(forKey: "dailyUsage") else {
            return [:]
        }
        
        do {
            return try JSONDecoder().decode([String: DailyUsageData].self, from: data)
        } catch {
            return [:]
        }
    }
    
    private func scheduleSessionEndNotification(for appId: String, at endTime: Date) {
        // Post notification that will be picked up by main app
        let center = NotificationCenter.default
        center.post(name: NSNotification.Name("SessionStartedInExtension"), object: [
            "appId": appId,
            "endTime": endTime.timeIntervalSince1970
        ])
    }
    
    private func logShieldAction(_ action: String, appId: String) {
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        
        let logEntry: [String: Any] = [
            "action": action,
            "appId": appId,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        var shieldLogs = defaults?.object(forKey: "shieldActionLogs") as? [[String: Any]] ?? []
        shieldLogs.append(logEntry)
        
        // Keep only last 50 entries
        if shieldLogs.count > 50 {
            shieldLogs = Array(shieldLogs.suffix(50))
        }
        
        defaults?.set(shieldLogs, forKey: "shieldActionLogs")
    }
    
    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}