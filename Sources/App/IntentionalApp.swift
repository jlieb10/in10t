import SwiftUI
import FamilyControls

@main
struct IntentionalApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Configure Firebase
        FirebaseConfig.configure()
        
        // Set up family controls authorization center delegate
        AuthorizationCenter.shared.delegate = appState.familyControlsService
        
        // Initialize services
        appState.initializeServices()
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.authState.isSignedIn {
                if appState.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingFlow()
                }
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut, value: appState.authState.isSignedIn)
        .animation(.easeInOut, value: appState.hasCompletedOnboarding)
    }
}