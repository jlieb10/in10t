import Foundation
import ManagedSettings
import FamilyControls

/// Service for managing app restrictions via ManagedSettings
class ManagedSettingsService: ObservableObject {
    static let shared = ManagedSettingsService()
    
    private let store = ManagedSettingsStore()
    private let appGroup = AppGroup.userDefaults
    
    // Track active sessions
    @Published private var activeSessions: [String: Date] = [:] // appId -> end time
    
    private init() {
        loadActiveSessions()
        setupTimer()
    }
    
    // MARK: - Shield Management
    
    func enableShields(for quotas: [AppQuota]) {
        var applications = Set<ApplicationToken>()
        var categories = Set<ActivityCategoryToken>()
        
        for quota in quotas where quota.isEnabled {
            if let appToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ApplicationToken.self, from: quota.tokenData) {
                applications.insert(appToken)
            } else if let categoryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ActivityCategoryToken.self, from: quota.tokenData) {
                categories.insert(categoryToken)
            }
        }
        
        // Apply restrictions
        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories = categories.isEmpty ? nil : .specific(categories)
    }
    
    func disableShields(for quotas: [AppQuota]) {
        var applicationsToRemove = Set<ApplicationToken>()
        var categoriesToRemove = Set<ActivityCategoryToken>()
        
        for quota in quotas {
            if let appToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ApplicationToken.self, from: quota.tokenData) {
                applicationsToRemove.insert(appToken)
            } else if let categoryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ActivityCategoryToken.self, from: quota.tokenData) {
                categoriesToRemove.insert(categoryToken)
            }
        }
        
        // Remove from current restrictions
        if let currentApps = store.shield.applications {
            let remaining = currentApps.subtracting(applicationsToRemove)
            store.shield.applications = remaining.isEmpty ? nil : remaining
        }
        
        if case .specific(let currentCategories) = store.shield.applicationCategories {
            let remaining = currentCategories.subtracting(categoriesToRemove)
            store.shield.applicationCategories = remaining.isEmpty ? nil : .specific(remaining)
        }
    }
    
    func clearAllShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        activeSessions.removeAll()
        saveActiveSessions()
    }
    
    // MARK: - Session Management
    
    func startSession(for quota: AppQuota, duration: TimeInterval) {
        let endTime = Date().addingTimeInterval(duration)
        activeSessions[quota.id] = endTime
        
        // Remove shields for this specific app during session
        if let appToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ApplicationToken.self, from: quota.tokenData) {
            var currentApps = store.shield.applications ?? Set<ApplicationToken>()
            currentApps.remove(appToken)
            store.shield.applications = currentApps.isEmpty ? nil : currentApps
        } else if let categoryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ActivityCategoryToken.self, from: quota.tokenData) {
            if case .specific(var currentCategories) = store.shield.applicationCategories {
                currentCategories.remove(categoryToken)
                store.shield.applicationCategories = currentCategories.isEmpty ? nil : .specific(currentCategories)
            }
        }
        
        saveActiveSessions()
        
        // Schedule session end
        scheduleSessionEnd(for: quota, at: endTime)
    }
    
    func endSession(for quota: AppQuota) {
        activeSessions.removeValue(forKey: quota.id)
        
        // Re-enable shields for this app
        if let appToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ApplicationToken.self, from: quota.tokenData) {
            var currentApps = store.shield.applications ?? Set<ApplicationToken>()
            currentApps.insert(appToken)
            store.shield.applications = currentApps
        } else if let categoryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ActivityCategoryToken.self, from: quota.tokenData) {
            if case .specific(var currentCategories) = store.shield.applicationCategories {
                currentCategories.insert(categoryToken)
                store.shield.applicationCategories = .specific(currentCategories)
            } else {
                store.shield.applicationCategories = .specific([categoryToken])
            }
        }
        
        saveActiveSessions()
    }
    
    func isSessionActive(for appId: String) -> Bool {
        guard let endTime = activeSessions[appId] else { return false }
        return Date() < endTime
    }
    
    func sessionTimeRemaining(for appId: String) -> TimeInterval {
        guard let endTime = activeSessions[appId] else { return 0 }
        return max(0, endTime.timeIntervalSinceNow)
    }
    
    // MARK: - Private Methods
    
    private func scheduleSessionEnd(for quota: AppQuota, at endTime: Date) {
        let timer = Timer(fireAt: endTime, interval: 0, target: self, selector: #selector(handleSessionEnd), userInfo: quota.id, repeats: false)
        let interval = endTime.timeIntervalSinceNow
        guard interval > 0 else {
            // If the end time is in the past, end the session immediately
            self.endSession(for: quota)
            return
        }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.endSession(for: quota)
            NotificationCenter.default.post(name: .sessionEnded, object: quota.id)
        }
    }
    
    @objc private func handleSessionEnd(_ timer: Timer) {
        guard let appId = timer.userInfo as? String else { return }
        
        // Find the quota and end the session
        // This would typically be coordinated with the session manager
        activeSessions.removeValue(forKey: appId)
        saveActiveSessions()
        
        // Post notification to update UI
        NotificationCenter.default.post(name: .sessionEnded, object: appId)
    }
    
    private func setupTimer() {
        // Check for expired sessions every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.checkForExpiredSessions()
        }
    }
    
    private func checkForExpiredSessions() {
        let now = Date()
        let expiredSessions = activeSessions.filter { $0.value <= now }
        
        for (appId, _) in expiredSessions {
            activeSessions.removeValue(forKey: appId)
            NotificationCenter.default.post(name: .sessionEnded, object: appId)
        }
        
        if !expiredSessions.isEmpty {
            saveActiveSessions()
        }
    }
    
    // MARK: - Persistence
    
    private func saveActiveSessions() {
        let data = activeSessions.mapValues { $0.timeIntervalSince1970 }
        appGroup.set(data, forKey: "activeSessions")
    }
    
    private func loadActiveSessions() {
        if let data = appGroup.object(forKey: "activeSessions") as? [String: TimeInterval] {
            activeSessions = data.mapValues { Date(timeIntervalSince1970: $0) }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let sessionEnded = Notification.Name("sessionEnded")
    static let sessionStarted = Notification.Name("sessionStarted")
}