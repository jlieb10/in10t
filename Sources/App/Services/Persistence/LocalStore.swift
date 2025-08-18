import Foundation

/// Local storage service using App Group UserDefaults and local database
class LocalStore: ObservableObject {
    private let userDefaults = AppGroup.userDefaults
    private let fileManager = FileManager.default
    private let containerURL = AppGroup.containerURL
    
    // MARK: - User Preferences
    
    var hasCompletedOnboarding: Bool {
        userDefaults.bool(forKey: UserDefaultsKeys.hasCompletedOnboarding)
    }
    
    func setOnboardingCompleted() {
        userDefaults.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)
    }
    
    // MARK: - User Profile
    
    func saveUserProfile(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: UserDefaultsKeys.userProfile)
        } catch {
            print("Failed to save user profile: \(error)")
        }
    }
    
    func loadUserProfile() -> UserProfile? {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.userProfile) else { return nil }
        
        do {
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            print("Failed to load user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - App Quotas
    
    func saveAppQuotas(_ quotas: [AppQuota]) {
        do {
            let data = try JSONEncoder().encode(quotas)
            userDefaults.set(data, forKey: UserDefaultsKeys.appQuotas)
        } catch {
            print("Failed to save app quotas: \(error)")
        }
    }
    
    func loadAppQuotas() -> [AppQuota] {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.appQuotas) else { return [] }
        
        do {
            return try JSONDecoder().decode([AppQuota].self, from: data)
        } catch {
            print("Failed to load app quotas: \(error)")
            return []
        }
    }
    
    // MARK: - Daily Usage
    
    func saveDailyUsage(_ usage: [String: DailyUsage]) {
        do {
            let data = try JSONEncoder().encode(usage)
            userDefaults.set(data, forKey: UserDefaultsKeys.dailyUsage)
        } catch {
            print("Failed to save daily usage: \(error)")
        }
    }
    
    func loadDailyUsage() -> [String: DailyUsage] {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.dailyUsage) else { return [:] }
        
        do {
            return try JSONDecoder().decode([String: DailyUsage].self, from: data)
        } catch {
            print("Failed to load daily usage: \(error)")
            return [:]
        }
    }
    
    // MARK: - Streak State
    
    func saveStreakState(_ streak: StreakState) {
        do {
            let data = try JSONEncoder().encode(streak)
            userDefaults.set(data, forKey: UserDefaultsKeys.streakState)
        } catch {
            print("Failed to save streak state: \(error)")
        }
    }
    
    func loadStreakState() -> StreakState {
        guard let data = userDefaults.data(forKey: UserDefaultsKeys.streakState) else { return StreakState() }
        
        do {
            return try JSONDecoder().decode(StreakState.self, from: data)
        } catch {
            print("Failed to load streak state: \(error)")
            return StreakState()
        }
    }
    
    // MARK: - Session Logs
    
    private var sessionLogsURL: URL {
        containerURL.appendingPathComponent("session_logs.json")
    }
    
    func saveSessionLog(_ log: SessionLog) {
        var logs = loadSessionLogs()
        logs.append(log)
        
        // Keep only last 1000 logs to prevent unlimited growth
        if logs.count > 1000 {
            logs = Array(logs.suffix(1000))
        }
        
        saveSessionLogs(logs)
    }
    
    func updateSessionLog(appId: String, endTime: Date, actualDuration: Int) {
        var logs = loadSessionLogs()
        
        if let index = logs.lastIndex(where: { $0.appId == appId && $0.end == nil }) {
            logs[index].end = endTime
            logs[index].durationSec = actualDuration
            saveSessionLogs(logs)
        }
    }
    
    func loadSessionLogs() -> [SessionLog] {
        guard let data = try? Data(contentsOf: sessionLogsURL) else { return [] }
        
        do {
            return try JSONDecoder().decode([SessionLog].self, from: data)
        } catch {
            print("Failed to load session logs: \(error)")
            return []
        }
    }
    
    private func saveSessionLogs(_ logs: [SessionLog]) {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: sessionLogsURL)
        } catch {
            print("Failed to save session logs: \(error)")
        }
    }
    
    func getSessionLogs(for appId: String? = nil, limit: Int? = nil) -> [SessionLog] {
        let allLogs = loadSessionLogs()
        
        var filtered = allLogs
        if let appId = appId {
            filtered = filtered.filter { $0.appId == appId }
        }
        
        // Sort by start date, most recent first
        filtered.sort { $0.start > $1.start }
        
        if let limit = limit {
            filtered = Array(filtered.prefix(limit))
        }
        
        return filtered
    }
    
    // MARK: - Subscription Status
    
    func saveSubscriptionStatus(_ status: SubscriptionStatus) {
        userDefaults.set(status.rawValue, forKey: UserDefaultsKeys.subscriptionStatus)
    }
    
    func loadSubscriptionStatus() -> SubscriptionStatus {
        guard let rawValue = userDefaults.string(forKey: UserDefaultsKeys.subscriptionStatus) else {
            return .free
        }
        return SubscriptionStatus(rawValue: rawValue) ?? .free
    }
    
    // MARK: - Sync State
    
    func saveLastSyncDate(_ date: Date) {
        userDefaults.set(date, forKey: UserDefaultsKeys.lastSyncDate)
    }
    
    func loadLastSyncDate() -> Date? {
        return userDefaults.object(forKey: UserDefaultsKeys.lastSyncDate) as? Date
    }
    
    // MARK: - Data Management
    
    func clearUserData() {
        let keys = [
            UserDefaultsKeys.userProfile,
            UserDefaultsKeys.appQuotas,
            UserDefaultsKeys.dailyUsage,
            UserDefaultsKeys.streakState,
            UserDefaultsKeys.subscriptionStatus,
            UserDefaultsKeys.lastSyncDate,
            UserDefaultsKeys.hasCompletedOnboarding
        ]
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
        
        // Clear session logs
        try? fileManager.removeItem(at: sessionLogsURL)
    }
    
    func exportUserData() -> Data? {
        let exportData: [String: Any] = [
            "userProfile": loadUserProfile() as Any,
            "appQuotas": loadAppQuotas(),
            "dailyUsage": loadDailyUsage(),
            "streakState": loadStreakState(),
            "sessionLogs": loadSessionLogs(),
            "subscriptionStatus": loadSubscriptionStatus().rawValue,
            "exportDate": Date().ISO8601Format()
        ]
        
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Failed to export user data: \(error)")
            return nil
        }
    }
    
    // MARK: - Health Check
    
    func getStorageInfo() -> [String: Any] {
        var info: [String: Any] = [:]
        
        info["hasCompletedOnboarding"] = hasCompletedOnboarding
        info["userProfile"] = loadUserProfile() != nil
        info["appQuotasCount"] = loadAppQuotas().count
        info["dailyUsageCount"] = loadDailyUsage().count
        info["sessionLogsCount"] = loadSessionLogs().count
        info["subscriptionStatus"] = loadSubscriptionStatus().rawValue
        info["lastSyncDate"] = loadLastSyncDate()?.ISO8601Format()
        
        return info
    }
}