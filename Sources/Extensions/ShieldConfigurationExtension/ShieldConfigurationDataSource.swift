import ManagedSettings
import UIKit

class ShieldConfigurationDataSource: ShieldConfigurationDataSource {
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        // Load app-specific configuration from shared storage
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        let appQuotas = loadAppQuotas(from: defaults)
        
        // Find the quota for this specific app
        let appQuota = findQuota(for: application, in: appQuotas)
        
        return createShieldConfiguration(for: appQuota, application: application)
    }
    
    override func configuration(shielding applicationCategory: ApplicationCategory) -> ShieldConfiguration {
        // Handle category-based shielding
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        let appQuotas = loadAppQuotas(from: defaults)
        
        // Find quota for this category
        let categoryQuota = findCategoryQuota(for: applicationCategory, in: appQuotas)
        
        return createShieldConfiguration(for: categoryQuota, category: applicationCategory)
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Handle web domain shielding (if implementing Safari extension)
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "hourglass.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Website Blocked",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This website is currently blocked. Set your intention to continue.",
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Set Intention",
                color: UIColor.systemBlue
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Not Now",
                color: UIColor.systemGray
            )
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func loadAppQuotas(from defaults: UserDefaults?) -> [AppQuotaData] {
        guard let defaults = defaults,
              let data = defaults.data(forKey: "appQuotas") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([AppQuotaData].self, from: data)
        } catch {
            print("Failed to decode app quotas in shield extension: \(error)")
            return []
        }
    }
    
    private func findQuota(for application: Application, in quotas: [AppQuotaData]) -> AppQuotaData? {
        // This is simplified - in reality, you'd need to match the application
        // token with the stored quota data
        return quotas.first { quota in
            // Match based on bundle identifier or other app characteristics
            quota.displayName.lowercased().contains(application.localizedDisplayName?.lowercased() ?? "")
        }
    }
    
    private func findCategoryQuota(for category: ApplicationCategory, in quotas: [AppQuotaData]) -> AppQuotaData? {
        // Find quota matching this category
        return quotas.first { quota in
            // Match category-based quotas
            quota.displayName.contains("Category")
        }
    }
    
    private func createShieldConfiguration(for quota: AppQuotaData?, application: Application? = nil, category: ApplicationCategory? = nil) -> ShieldConfiguration {
        let appName: String
        let intention: String
        let sessionLength: Int
        let sessionsRemaining: Int
        
        if let quota = quota {
            appName = quota.displayName
            intention = quota.intention ?? "Use this app mindfully"
            sessionLength = quota.sessionMinutes
            
            // Calculate remaining sessions for today
            let usage = getDailyUsage(for: quota.id)
            sessionsRemaining = max(0, quota.sessionsPerDay - usage.sessionsUsed)
        } else {
            appName = application?.localizedDisplayName ?? "This App"
            intention = "Use this app mindfully"
            sessionLength = 10
            sessionsRemaining = 1
        }
        
        // Determine button configuration based on remaining sessions
        let (primaryButtonText, primaryButtonEnabled) = getButtonConfiguration(
            sessionsRemaining: sessionsRemaining,
            sessionLength: sessionLength
        )
        
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(systemName: "hourglass.circle.fill"),
            title: ShieldConfiguration.Label(
                text: "Set Your Intention",
                color: UIColor.label
            ),
            subtitle: ShieldConfiguration.Label(
                text: intention,
                color: UIColor.secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: primaryButtonText,
                color: primaryButtonEnabled ? UIColor.systemBlue : UIColor.systemGray
            ),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Not Now",
                color: UIColor.systemGray
            )
        )
    }
    
    private func getButtonConfiguration(sessionsRemaining: Int, sessionLength: Int) -> (String, Bool) {
        if sessionsRemaining <= 0 {
            return ("Limit Reached - Back Tomorrow", false)
        } else {
            return ("Start \(sessionLength) min session", true)
        }
    }
    
    private func getDailyUsage(for appId: String) -> DailyUsageData {
        let defaults = UserDefaults(suiteName: "group.com.jlieb10.intentional")
        guard let data = defaults?.data(forKey: "dailyUsage") else {
            return DailyUsageData(appId: appId, dateKey: todayKey(), sessionsUsed: 0)
        }
        
        do {
            let usageDict = try JSONDecoder().decode([String: DailyUsageData].self, from: data)
            return usageDict[appId] ?? DailyUsageData(appId: appId, dateKey: todayKey(), sessionsUsed: 0)
        } catch {
            return DailyUsageData(appId: appId, dateKey: todayKey(), sessionsUsed: 0)
        }
    }
    
    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Data Structures (simplified for extension)

struct AppQuotaData: Codable {
    let id: String
    let displayName: String
    let sessionMinutes: Int
    let sessionsPerDay: Int
    let intention: String?
    let isEnabled: Bool
}

struct DailyUsageData: Codable {
    let appId: String
    let dateKey: String
    var sessionsUsed: Int
}