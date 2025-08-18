import Foundation
import Combine
import FamilyControls

/// Central application state manager
@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var authState = AuthState()
    @Published var hasCompletedOnboarding = false
    @Published var appQuotas: [AppQuota] = []
    @Published var dailyUsage: [String: DailyUsage] = [:] // keyed by appId
    @Published var streakState = StreakState()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    lazy var familyControlsService = FamilyControlsService()
    lazy var localStore = LocalStore()
    lazy var cloudStore = CloudStore()
    lazy var authService = AuthService()
    lazy var sessionManager = SessionManager()
    lazy var storeKitService = StoreKitService()
    lazy var notificationService = NotificationService()
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadLocalState()
        setupSubscriptions()
    }
    
    func initializeServices() {
        // Initialize all services with proper dependencies
        sessionManager.configure(with: self)
        storeKitService.configure()
        
        // Load user state if signed in
        if authState.isSignedIn {
            Task {
                await syncWithCloud()
            }
        }
    }
    
    // MARK: - State Management
    
    private func loadLocalState() {
        hasCompletedOnboarding = localStore.hasCompletedOnboarding
        appQuotas = localStore.loadAppQuotas()
        dailyUsage = localStore.loadDailyUsage()
        streakState = localStore.loadStreakState()
        
        // Load auth state
        if let profile = localStore.loadUserProfile() {
            authState.userProfile = profile
            authState.isSignedIn = true
        }
    }
    
    private func setupSubscriptions() {
        // Sync changes to local storage
        $appQuotas
            .dropFirst()
            .sink { [weak self] quotas in
                self?.localStore.saveAppQuotas(quotas)
                self?.syncAppQuotasToCloud()
            }
            .store(in: &cancellables)
        
        $dailyUsage
            .dropFirst()
            .sink { [weak self] usage in
                self?.localStore.saveDailyUsage(usage)
            }
            .store(in: &cancellables)
        
        $streakState
            .dropFirst()
            .sink { [weak self] streak in
                self?.localStore.saveStreakState(streak)
            }
            .store(in: &cancellables)
        
        // Listen to auth state changes
        authState.$isSignedIn
            .dropFirst()
            .sink { [weak self] isSignedIn in
                if isSignedIn {
                    Task {
                        await self?.syncWithCloud()
                    }
                } else {
                    self?.clearUserData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    func addAppQuota(_ quota: AppQuota) {
        appQuotas.append(quota)
    }
    
    func updateAppQuota(_ quota: AppQuota) {
        if let index = appQuotas.firstIndex(where: { $0.id == quota.id }) {
            appQuotas[index] = quota
        }
    }
    
    func removeAppQuota(id: String) {
        appQuotas.removeAll { $0.id == id }
        dailyUsage.removeValue(forKey: id)
    }
    
    func getDailyUsage(for appId: String) -> DailyUsage {
        let today = Date().dateKey
        return dailyUsage[appId] ?? DailyUsage(appId: appId, dateKey: today)
    }
    
    func updateDailyUsage(_ usage: DailyUsage) {
        dailyUsage[usage.appId] = usage
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        localStore.setOnboardingCompleted()
    }
    
    // MARK: - Cloud Sync
    
    func syncWithCloud() async {
        guard authState.isSignedIn, let userId = authState.userProfile?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Sync app quotas
            let cloudQuotas = try await cloudStore.loadAppQuotas(for: userId)
            if !cloudQuotas.isEmpty {
                appQuotas = cloudQuotas
            }
            
            // Sync streak state
            if let cloudStreak = try await cloudStore.loadStreakState(for: userId) {
                streakState = cloudStreak
            }
            
        } catch {
            errorMessage = "Failed to sync with cloud: \(error.localizedDescription)"
        }
    }
    
    private func syncAppQuotasToCloud() {
        guard authState.isSignedIn, let userId = authState.userProfile?.uid else { return }
        
        Task {
            do {
                try await cloudStore.saveAppQuotas(appQuotas, for: userId)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to sync quotas: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func clearUserData() {
        appQuotas = []
        dailyUsage = [:]
        streakState = StreakState()
        hasCompletedOnboarding = false
        localStore.clearUserData()
    }
}

/// Authentication state management
class AuthState: ObservableObject {
    @Published var isSignedIn = false
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    
    var subscriptionStatus: SubscriptionStatus {
        userProfile?.subscriptionStatus ?? .free
    }
    
    func signIn(with profile: UserProfile) {
        userProfile = profile
        isSignedIn = true
    }
    
    func signOut() {
        userProfile = nil
        isSignedIn = false
    }
}