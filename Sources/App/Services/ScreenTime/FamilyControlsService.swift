import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

/// Service for managing Family Controls authorization and app selection
@MainActor
class FamilyControlsService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var selectedApps: FamilyActivitySelection = FamilyActivitySelection()
    
    private let authorizationCenter = AuthorizationCenter.shared
    private let managedSettingsService = ManagedSettingsService.shared
    
    override init() {
        super.init()
        checkAuthorizationStatus()
        authorizationCenter.delegate = self
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
            throw FamilyControlsError.authorizationFailed(error.localizedDescription)
        }
    }
    
    private func checkAuthorizationStatus() {
        switch authorizationCenter.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - App Selection
    
    func presentFamilyActivityPicker() {
        // This will be handled by SwiftUI FamilyActivityPicker
        // The selection will be captured in the view
    }
    
    func updateSelectedApps(_ selection: FamilyActivitySelection) {
        selectedApps = selection
    }
    
    // MARK: - Token Management
    
    func createAppQuotas(from selection: FamilyActivitySelection) -> [AppQuota] {
        var quotas: [AppQuota] = []
        
        // Process application tokens
        for token in selection.applicationTokens {
            do {
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                let displayName = token.localizedDisplayName ?? "Unknown App"
                
                let quota = AppQuota(
                    tokenData: tokenData,
                    displayName: displayName,
                    sessionMinutes: 10, // Default values
                    sessionsPerDay: 1
                )
                
                quotas.append(quota)
            } catch {
                print("Failed to archive application token: \(error)")
            }
        }
        
        // Process category tokens (if any)
        for token in selection.categoryTokens {
            do {
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
                let displayName = token.localizedDisplayName ?? "Category"
                
                let quota = AppQuota(
                    tokenData: tokenData,
                    displayName: displayName,
                    sessionMinutes: 10,
                    sessionsPerDay: 1
                )
                
                quotas.append(quota)
            } catch {
                print("Failed to archive category token: \(error)")
            }
        }
        
        return quotas
    }
    
    func applicationToken(from quota: AppQuota) -> ApplicationToken? {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: ApplicationToken.self, from: quota.tokenData)
        } catch {
            print("Failed to unarchive application token: \(error)")
            return nil
        }
    }
    
    func categoryToken(from quota: AppQuota) -> ActivityCategoryToken? {
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: ActivityCategoryToken.self, from: quota.tokenData)
        } catch {
            print("Failed to unarchive category token: \(error)")
            return nil
        }
    }
    
    // MARK: - Shield Management
    
    func enableShields(for quotas: [AppQuota]) {
        managedSettingsService.enableShields(for: quotas)
    }
    
    func disableShields(for quotas: [AppQuota]) {
        managedSettingsService.disableShields(for: quotas)
    }
    
    func startSession(for quota: AppQuota, duration: TimeInterval) {
        managedSettingsService.startSession(for: quota, duration: duration)
    }
    
    func endSession(for quota: AppQuota) {
        managedSettingsService.endSession(for: quota)
    }
}

// MARK: - AuthorizationCenterDelegate

extension FamilyControlsService: AuthorizationCenterDelegate {
    func authorizationCenter(_ center: AuthorizationCenter, didChangeAuthorizationFor status: AuthorizationStatus) {
        DispatchQueue.main.async {
            switch status {
            case .approved:
                self.isAuthorized = true
            case .denied, .notDetermined:
                self.isAuthorized = false
            @unknown default:
                self.isAuthorized = false
            }
        }
    }
}

// MARK: - Errors

enum FamilyControlsError: LocalizedError {
    case authorizationFailed(String)
    case notAuthorized
    case tokenProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let message):
            return "Family Controls authorization failed: \(message)"
        case .notAuthorized:
            return "Family Controls authorization is required to use this feature."
        case .tokenProcessingFailed:
            return "Failed to process app selection tokens."
        }
    }
}