import Foundation

/// App Group configuration for sharing data between main app and extensions
enum AppGroup {
    static let identifier = "group.com.jlieb10.intentional"
    
    static var userDefaults: UserDefaults {
        guard let defaults = UserDefaults(suiteName: identifier) else {
            fatalError("Failed to create UserDefaults with App Group identifier")
        }
        return defaults
    }
    
    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            fatalError("Failed to get App Group container URL")
        }
        return url
    }
}

/// UserDefaults keys for consistent data access
enum UserDefaultsKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let userProfile = "userProfile"
    static let appQuotas = "appQuotas"
    static let dailyUsage = "dailyUsage"
    static let streakState = "streakState"
    static let subscriptionStatus = "subscriptionStatus"
    static let lastSyncDate = "lastSyncDate"
}

/// Bundle identifiers for the app and extensions
enum BundleIdentifiers {
    static let mainApp = "com.jlieb10.intentional"
    static let deviceActivityMonitor = "com.jlieb10.intentional.DeviceActivityMonitor"
    static let shieldConfiguration = "com.jlieb10.intentional.ShieldConfiguration"
    static let shieldAction = "com.jlieb10.intentional.ShieldAction"
    static let widgets = "com.jlieb10.intentional.Widgets"
}

/// Firebase and external service configuration
enum FirebaseConfig {
    static func configure() {
        // Firebase configuration will be loaded from GoogleService-Info.plist
        #if canImport(Firebase)
        import Firebase
        FirebaseApp.configure()
        #endif
    }
}

/// App version and build information
enum AppVersion {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var displayVersion: String {
        "\(version) (\(build))"
    }
}

/// Environment-specific configurations
enum Environment {
    #if DEBUG
    static let isDebug = true
    #else
    static let isDebug = false
    #endif
    
    static let cloudSyncEnabled = true
    static let analyticsEnabled = !isDebug
    
    // Subscription product IDs
    static let monthlySubscriptionID = "intentional_pro_monthly"
    static let annualSubscriptionID = "intentional_pro_annual"
}