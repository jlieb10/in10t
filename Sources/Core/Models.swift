import Foundation
import FamilyControls

// MARK: - Core Data Models

/// Represents quota settings for a specific app
struct AppQuota: Identifiable, Codable, Equatable {
    let id: String              // stable token id
    let tokenData: Data         // ApplicationToken archived
    var displayName: String
    var sessionMinutes: Int     // per session (X)
    var sessionsPerDay: Int     // quota (Y) 
    var intention: String?      // optional one-liner
    var allowGraceMinutes: Int? // e.g., 2 (Pro feature)
    var isEnabled: Bool
    
    // Computed properties
    var sessionDuration: TimeInterval {
        TimeInterval(sessionMinutes * 60)
    }
    
    var graceDuration: TimeInterval {
        TimeInterval((allowGraceMinutes ?? 0) * 60)
    }
    
    init(
        id: String = UUID().uuidString,
        tokenData: Data,
        displayName: String,
        sessionMinutes: Int = 10,
        sessionsPerDay: Int = 1,
        intention: String? = nil,
        allowGraceMinutes: Int? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.tokenData = tokenData
        self.displayName = displayName
        self.sessionMinutes = sessionMinutes
        self.sessionsPerDay = sessionsPerDay
        self.intention = intention
        self.allowGraceMinutes = allowGraceMinutes
        self.isEnabled = isEnabled
    }
}

/// Tracks daily usage for a specific app
struct DailyUsage: Codable, Equatable {
    let appId: String
    let dateKey: String         // "YYYY-MM-DD" in local tz
    var sessionsUsed: Int
    var secondsUsedThisSession: Int // tracks in-progress
    
    init(appId: String, dateKey: String, sessionsUsed: Int = 0, secondsUsedThisSession: Int = 0) {
        self.appId = appId
        self.dateKey = dateKey
        self.sessionsUsed = sessionsUsed
        self.secondsUsedThisSession = secondsUsedThisSession
    }
    
    var isQuotaExhausted: Bool {
        // This will be checked against AppQuota.sessionsPerDay
        false // Implementation will compare with quota
    }
}

/// Manages streak tracking for compliance
struct StreakState: Codable, Equatable {
    var current: Int
    var longest: Int
    var lastCompliantDateKey: String?
    
    init(current: Int = 0, longest: Int = 0, lastCompliantDateKey: String? = nil) {
        self.current = current
        self.longest = longest
        self.lastCompliantDateKey = lastCompliantDateKey
    }
    
    mutating func recordCompliantDay(dateKey: String) {
        if let lastKey = lastCompliantDateKey,
           let lastDate = DateFormatter.dateKey.date(from: lastKey),
           let currentDate = DateFormatter.dateKey.date(from: dateKey) {
            
            let calendar = Calendar.current
            if calendar.isDate(currentDate, inSameDayAs: lastDate.addingTimeInterval(86400)) {
                // Consecutive day
                current += 1
            } else if calendar.isDate(currentDate, inSameDayAs: lastDate) {
                // Same day, no change
                return
            } else {
                // Non-consecutive, reset
                current = 1
            }
        } else {
            // First day or invalid last date
            current = 1
        }
        
        longest = max(longest, current)
        lastCompliantDateKey = dateKey
    }
    
    mutating func recordNonCompliantDay() {
        current = 0
    }
}

/// Individual session log entry
struct SessionLog: Codable, Identifiable, Equatable {
    let id: String
    let appId: String
    let start: Date
    var end: Date?
    var durationSec: Int
    let startedViaShield: Bool
    let quotaAtStart: Int
    
    init(
        id: String = UUID().uuidString,
        appId: String,
        start: Date = Date(),
        end: Date? = nil,
        durationSec: Int = 0,
        startedViaShield: Bool = true,
        quotaAtStart: Int
    ) {
        self.id = id
        self.appId = appId
        self.start = start
        self.end = end
        self.durationSec = durationSec
        self.startedViaShield = startedViaShield
        self.quotaAtStart = quotaAtStart
    }
    
    var isActive: Bool {
        end == nil
    }
    
    var actualDuration: TimeInterval {
        if let endTime = end {
            return endTime.timeIntervalSince(start)
        } else {
            return Date().timeIntervalSince(start)
        }
    }
}

// MARK: - User Profile

/// User authentication and profile information
struct UserProfile: Codable, Equatable {
    let uid: String
    let email: String?
    let displayName: String?
    let creationDate: Date
    var lastSignIn: Date
    var subscriptionStatus: SubscriptionStatus
    
    init(
        uid: String,
        email: String? = nil,
        displayName: String? = nil,
        creationDate: Date = Date(),
        lastSignIn: Date = Date(),
        subscriptionStatus: SubscriptionStatus = .free
    ) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.creationDate = creationDate
        self.lastSignIn = lastSignIn
        self.subscriptionStatus = subscriptionStatus
    }
}

/// Subscription tier management
enum SubscriptionStatus: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case proTrial = "pro_trial"
    
    var isPro: Bool {
        self == .pro || self == .proTrial
    }
    
    var displayName: String {
        switch self {
        case .free:
            return "Free"
        case .pro:
            return "Pro"
        case .proTrial:
            return "Pro Trial"
        }
    }
}

// MARK: - Helper Extensions

extension DateFormatter {
    static let dateKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

extension Date {
    var dateKey: String {
        DateFormatter.dateKey.string(from: self)
    }
}