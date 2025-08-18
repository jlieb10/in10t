import Foundation
import Firebase
import FirebaseFirestore

/// Cloud storage service using Firebase Firestore
class CloudStore: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - Collections
    private func userDocument(for userId: String) -> DocumentReference {
        db.collection("users").document(userId)
    }
    
    private func appQuotasCollection(for userId: String) -> CollectionReference {
        userDocument(for: userId).collection("appQuotas")
    }
    
    private func sessionLogsCollection(for userId: String) -> CollectionReference {
        userDocument(for: userId).collection("sessionLogs")
    }
    
    // MARK: - User Profile
    
    func saveUserProfile(_ profile: UserProfile) async throws {
        let data: [String: Any] = [
            "uid": profile.uid,
            "email": profile.email ?? NSNull(),
            "displayName": profile.displayName ?? NSNull(),
            "creationDate": Timestamp(date: profile.creationDate),
            "lastSignIn": Timestamp(date: profile.lastSignIn),
            "subscriptionStatus": profile.subscriptionStatus.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await userDocument(for: profile.uid).setData(data, merge: true)
    }
    
    func loadUserProfile(for userId: String) async throws -> UserProfile? {
        let document = try await userDocument(for: userId).getDocument()
        
        guard document.exists, let data = document.data() else { return nil }
        
        return UserProfile(
            uid: data["uid"] as? String ?? userId,
            email: data["email"] as? String,
            displayName: data["displayName"] as? String,
            creationDate: (data["creationDate"] as? Timestamp)?.dateValue() ?? Date(),
            lastSignIn: (data["lastSignIn"] as? Timestamp)?.dateValue() ?? Date(),
            subscriptionStatus: SubscriptionStatus(rawValue: data["subscriptionStatus"] as? String ?? "free") ?? .free
        )
    }
    
    // MARK: - App Quotas
    
    func saveAppQuotas(_ quotas: [AppQuota], for userId: String) async throws {
        let batch = db.batch()
        let collection = appQuotasCollection(for: userId)
        
        // Clear existing quotas
        let existingDocs = try await collection.getDocuments()
        for doc in existingDocs.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Add new quotas
        for quota in quotas {
            let docRef = collection.document(quota.id)
            let data: [String: Any] = [
                "id": quota.id,
                "tokenData": quota.tokenData,
                "displayName": quota.displayName,
                "sessionMinutes": quota.sessionMinutes,
                "sessionsPerDay": quota.sessionsPerDay,
                "intention": quota.intention ?? NSNull(),
                "allowGraceMinutes": quota.allowGraceMinutes ?? NSNull(),
                "isEnabled": quota.isEnabled,
                "updatedAt": Timestamp(date: Date())
            ]
            batch.setData(data, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    func loadAppQuotas(for userId: String) async throws -> [AppQuota] {
        let snapshot = try await appQuotasCollection(for: userId).getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            
            guard let id = data["id"] as? String,
                  let tokenData = data["tokenData"] as? Data,
                  let displayName = data["displayName"] as? String,
                  let sessionMinutes = data["sessionMinutes"] as? Int,
                  let sessionsPerDay = data["sessionsPerDay"] as? Int else {
                return nil
            }
            
            return AppQuota(
                id: id,
                tokenData: tokenData,
                displayName: displayName,
                sessionMinutes: sessionMinutes,
                sessionsPerDay: sessionsPerDay,
                intention: data["intention"] as? String,
                allowGraceMinutes: data["allowGraceMinutes"] as? Int,
                isEnabled: data["isEnabled"] as? Bool ?? true
            )
        }
    }
    
    // MARK: - Streak State
    
    func saveStreakState(_ streak: StreakState, for userId: String) async throws {
        let data: [String: Any] = [
            "current": streak.current,
            "longest": streak.longest,
            "lastCompliantDateKey": streak.lastCompliantDateKey ?? NSNull(),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await userDocument(for: userId).collection("metadata").document("streak").setData(data)
    }
    
    func loadStreakState(for userId: String) async throws -> StreakState? {
        let document = try await userDocument(for: userId).collection("metadata").document("streak").getDocument()
        
        guard document.exists, let data = document.data() else { return nil }
        
        return StreakState(
            current: data["current"] as? Int ?? 0,
            longest: data["longest"] as? Int ?? 0,
            lastCompliantDateKey: data["lastCompliantDateKey"] as? String
        )
    }
    
    // MARK: - Session Logs
    
    func saveSessionLogs(_ logs: [SessionLog], for userId: String) async throws {
        let batch = db.batch()
        let collection = sessionLogsCollection(for: userId)
        
        for log in logs {
            let docRef = collection.document(log.id)
            let data: [String: Any] = [
                "id": log.id,
                "appId": log.appId,
                "start": Timestamp(date: log.start),
                "end": log.end != nil ? Timestamp(date: log.end!) : NSNull(),
                "durationSec": log.durationSec,
                "startedViaShield": log.startedViaShield,
                "quotaAtStart": log.quotaAtStart,
                "createdAt": Timestamp(date: Date())
            ]
            batch.setData(data, forDocument: docRef, merge: true)
        }
        
        try await batch.commit()
    }
    
    func loadSessionLogs(for userId: String, limit: Int = 100) async throws -> [SessionLog] {
        let query = sessionLogsCollection(for: userId)
            .order(by: "start", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            
            guard let id = data["id"] as? String,
                  let appId = data["appId"] as? String,
                  let startTimestamp = data["start"] as? Timestamp,
                  let durationSec = data["durationSec"] as? Int,
                  let startedViaShield = data["startedViaShield"] as? Bool,
                  let quotaAtStart = data["quotaAtStart"] as? Int else {
                return nil
            }
            
            let endDate: Date?
            if let endTimestamp = data["end"] as? Timestamp {
                endDate = endTimestamp.dateValue()
            } else {
                endDate = nil
            }
            
            return SessionLog(
                id: id,
                appId: appId,
                start: startTimestamp.dateValue(),
                end: endDate,
                durationSec: durationSec,
                startedViaShield: startedViaShield,
                quotaAtStart: quotaAtStart
            )
        }
    }
    
    // MARK: - Batch Operations
    
    func syncUserData(_ profile: UserProfile, quotas: [AppQuota], streak: StreakState, recentLogs: [SessionLog]) async throws {
        // Start with user profile
        try await saveUserProfile(profile)
        
        // Save quotas and streak in parallel
        async let quotasTask = saveAppQuotas(quotas, for: profile.uid)
        async let streakTask = saveStreakState(streak, for: profile.uid)
        async let logsTask = saveSessionLogs(recentLogs, for: profile.uid)
        
        try await quotasTask
        try await streakTask
        try await logsTask
    }
    
    // MARK: - Data Cleanup
    
    func deleteUserData(for userId: String) async throws {
        let batch = db.batch()
        
        // Delete app quotas
        let quotasDocs = try await appQuotasCollection(for: userId).getDocuments()
        for doc in quotasDocs.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Delete session logs (in batches if many)
        let logsDocs = try await sessionLogsCollection(for: userId).limit(to: 500).getDocuments()
        for doc in logsDocs.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Delete metadata
        let metadataCollection = userDocument(for: userId).collection("metadata")
        let metadataDocs = try await metadataCollection.getDocuments()
        for doc in metadataDocs.documents {
            batch.deleteDocument(doc.reference)
        }
        
        // Delete user document
        batch.deleteDocument(userDocument(for: userId))
        
        try await batch.commit()
        
        // If there were more than 500 session logs, recursively delete more
        if logsDocs.documents.count == 500 {
            try await deleteUserData(for: userId)
        }
    }
}

// MARK: - Cloud Storage Error

enum CloudStoreError: LocalizedError {
    case userNotFound
    case syncFailed(String)
    case deleteOperationFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User data not found in cloud storage."
        case .syncFailed(let reason):
            return "Cloud sync failed: \(reason)"
        case .deleteOperationFailed:
            return "Failed to delete user data from cloud storage."
        }
    }
}