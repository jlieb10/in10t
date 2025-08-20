import Foundation
#if canImport(FirebaseCore)
import FirebaseCore
#endif

/// Firebase configuration helper that gracefully handles missing GoogleService-Info.plist
enum FirebaseConfig {
    /// Configure Firebase if GoogleService-Info.plist exists, otherwise skip gracefully
    static func configure() {
        // Check if GoogleService-Info.plist exists
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            #if canImport(FirebaseCore)
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
            #else
            print("⚠️ Firebase framework not available")
            #endif
        } else {
            print("ℹ️ Skipping FirebaseApp.configure(): GoogleService-Info.plist not found")
            print("   Add your GoogleService-Info.plist file to enable Firebase features")
        }
    }
}