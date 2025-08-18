import Foundation
import Combine
import ActivityKit

/// Manages active sessions and coordinates with Screen Time APIs
@MainActor
class SessionManager: ObservableObject {
    @Published var activeSessions: [String: ActiveSession] = [:]
    
    private var appState: AppState?
    private var cancellables = Set<AnyCancellable>()
    private var liveActivityService = LiveActivityService.shared
    
    struct ActiveSession {
        let appId: String
        let startTime: Date
        let duration: TimeInterval
        let hasGrace: Bool
        var liveActivityId: String?
        
        var endTime: Date {
            startTime.addingTimeInterval(duration)
        }
        
        var timeRemaining: TimeInterval {
            max(0, endTime.timeIntervalSinceNow)
        }
        
        var isExpired: Bool {
            timeRemaining <= 0
        }
    }
    
    func configure(with appState: AppState) {
        self.appState = appState
        loadActiveSessions()
        setupSessionMonitoring()
    }
    
    // MARK: - Session Control
    
    func startSession(for quota: AppQuota, withGrace: Bool = false) async throws {
        guard let appState = appState else { return }
        
        // Check if session is already active
        if activeSessions[quota.id] != nil {
            throw SessionError.sessionAlreadyActive
        }
        
        // Check daily quota
        var usage = appState.getDailyUsage(for: quota.id)
        guard usage.sessionsUsed < quota.sessionsPerDay else {
            throw SessionError.dailyQuotaExhausted
        }
        
        // Calculate session duration
        var sessionDuration = quota.sessionDuration
        if withGrace, let graceMinutes = quota.allowGraceMinutes {
            sessionDuration += TimeInterval(graceMinutes * 60)
        }
        
        // Create active session
        let session = ActiveSession(
            appId: quota.id,
            startTime: Date(),
            duration: sessionDuration,
            hasGrace: withGrace
        )
        
        activeSessions[quota.id] = session
        
        // Update daily usage
        usage.sessionsUsed += 1
        usage.secondsUsedThisSession = 0
        appState.updateDailyUsage(usage)
        
        // Start Live Activity
        let liveActivityId = try await liveActivityService.startSessionActivity(
            appName: quota.displayName,
            duration: sessionDuration
        )
        
        activeSessions[quota.id]?.liveActivityId = liveActivityId
        
        // Remove app from shields
        appState.familyControlsService.startSession(for: quota, duration: sessionDuration)
        
        // Create session log
        let sessionLog = SessionLog(
            appId: quota.id,
            start: session.startTime,
            durationSec: Int(sessionDuration),
            startedViaShield: true,
            quotaAtStart: usage.sessionsUsed
        )
        
        appState.localStore.saveSessionLog(sessionLog)
        
        // Schedule session end
        scheduleSessionEnd(for: quota.id, at: session.endTime)
        
        // Save state
        saveActiveSessions()
        
        // Post notification
        NotificationCenter.default.post(name: .sessionStarted, object: quota.id)
    }
    
    func endSession(for appId: String) {
        guard let session = activeSessions[appId],
              let appState = appState,
              let quota = appState.appQuotas.first(where: { $0.id == appId }) else {
            return
        }
        
        // End Live Activity
        if let liveActivityId = session.liveActivityId {
            liveActivityService.endActivity(id: liveActivityId)
        }
        
        // Re-enable shields
        appState.familyControlsService.endSession(for: quota)
        
        // Update session log
        let actualDuration = Date().timeIntervalSince(session.startTime)
        appState.localStore.updateSessionLog(
            appId: appId,
            endTime: Date(),
            actualDuration: Int(actualDuration)
        )
        
        // Remove from active sessions
        activeSessions.removeValue(forKey: appId)
        saveActiveSessions()
        
        // Post notification
        NotificationCenter.default.post(name: .sessionEnded, object: appId)
        
        // Schedule notification for streak checking
        scheduleStreakUpdate()
    }
    
    func isSessionActive(for appId: String) -> Bool {
        guard let session = activeSessions[appId] else { return false }
        return !session.isExpired
    }
    
    func timeRemaining(for appId: String) -> TimeInterval {
        guard let session = activeSessions[appId] else { return 0 }
        return session.timeRemaining
    }
    
    // MARK: - Private Methods
    
    private func setupSessionMonitoring() {
        // Check for expired sessions every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForExpiredSessions()
            }
        }
    }
    
    private func checkForExpiredSessions() {
        let expiredSessions = activeSessions.filter { $0.value.isExpired }
        
        for (appId, _) in expiredSessions {
            endSession(for: appId)
        }
    }
    
    private func scheduleSessionEnd(for appId: String, at endTime: Date) {
        let timer = Timer(fireAt: endTime, interval: 0, target: self, selector: #selector(handleScheduledSessionEnd), userInfo: appId, repeats: false)
        RunLoop.main.add(timer, forMode: .common)
    }
    
    @objc private func handleScheduledSessionEnd(_ timer: Timer) {
        guard let appId = timer.userInfo as? String else { return }
        endSession(for: appId)
    }
    
    private func scheduleStreakUpdate() {
        // Check streak status at end of day
        let calendar = Calendar.current
        guard let endOfDay = calendar.dateInterval(of: .day, for: Date())?.end else { return }
        
        let timer = Timer(fireAt: endOfDay, interval: 0, target: self, selector: #selector(updateStreakStatus), userInfo: nil, repeats: false)
        let interval = endTime.timeIntervalSinceNow
        guard interval > 0 else {
            // If the end time is in the past, end the session immediately
            endSession(for: appId)
            return
        }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.endSession(for: appId)
        }
    }
    
        guard let endOfDay = calendar.dateInterval(of: .day, for: Date())?.end else { return }
        
        let interval = endOfDay.timeIntervalSinceNow
        guard interval > 0 else {
            // If end of day is in the past, update streak status immediately
            updateStreakStatus()
            return
        }
        Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.updateStreakStatus()
        }
    }
    
    @objc private func updateStreakStatus() {
        guard let appState = appState else { return }
        
        let today = Date().dateKey
        let allQuotasComplied = appState.appQuotas.allSatisfy { quota in
            let usage = appState.getDailyUsage(for: quota.id)
            return usage.sessionsUsed <= quota.sessionsPerDay
        }
        
        if allQuotasComplied {
            appState.streakState.recordCompliantDay(dateKey: today)
        } else {
            appState.streakState.recordNonCompliantDay()
        }
    }
    
    // MARK: - Persistence
    
    private func saveActiveSessions() {
        let data = activeSessions.mapValues { session in
            [
                "appId": session.appId,
                "startTime": session.startTime.timeIntervalSince1970,
                "duration": session.duration,
                "hasGrace": session.hasGrace,
                "liveActivityId": session.liveActivityId as Any
            ]
        }
        
        AppGroup.userDefaults.set(data, forKey: "activeSessionsV2")
    }
    
    private func loadActiveSessions() {
        guard let data = AppGroup.userDefaults.object(forKey: "activeSessionsV2") as? [String: [String: Any]] else {
            return
        }
        
        for (appId, sessionData) in data {
            guard let appIdValue = sessionData["appId"] as? String,
                  let startTimeInterval = sessionData["startTime"] as? TimeInterval,
                  let duration = sessionData["duration"] as? TimeInterval,
                  let hasGrace = sessionData["hasGrace"] as? Bool else {
                continue
            }
            
            let liveActivityId = sessionData["liveActivityId"] as? String
            
            var session = ActiveSession(
                appId: appIdValue,
                startTime: Date(timeIntervalSince1970: startTimeInterval),
                duration: duration,
                hasGrace: hasGrace
            )
            session.liveActivityId = liveActivityId
            
            // Only restore non-expired sessions
            if !session.isExpired {
                activeSessions[appId] = session
            }
        }
    }
}

// MARK: - Errors

enum SessionError: LocalizedError {
    case sessionAlreadyActive
    case dailyQuotaExhausted
    case appNotFound
    case liveActivityFailed
    
    var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:
            return "A session is already active for this app."
        case .dailyQuotaExhausted:
            return "You've reached your daily session limit for this app."
        case .appNotFound:
            return "App configuration not found."
        case .liveActivityFailed:
            return "Failed to start Live Activity countdown."
        }
    }
}