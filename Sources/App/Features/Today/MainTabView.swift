import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Today")
                }
            
            QuotaListView()
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Apps")
                }
            
            SessionLogView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .tint(.blue)
    }
}

struct TodayView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with streak
                    headerView
                    
                    // App cards
                    if appState.appQuotas.isEmpty {
                        emptyStateView
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(appState.appQuotas) { quota in
                                SessionCardView(quota: quota)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appState.authState.subscriptionStatus == .free {
                        Button("Upgrade") {
                            showingPaywall = true
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .refreshable {
            await appState.syncWithCloud()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Streak display
            if appState.streakState.current > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Streak: \(appState.streakState.current) days")
                        .font(.headline)
                        .fontWeight(.medium)
                    if appState.streakState.current == appState.streakState.longest {
                        Text("🎉")
                    }
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Daily summary
            let totalSessions = appState.appQuotas.reduce(0) { sum, quota in
                sum + appState.getDailyUsage(for: quota.id).sessionsUsed
            }
            
            let totalQuota = appState.appQuotas.reduce(0) { sum, quota in
                sum + quota.sessionsPerDay
            }
            
            if totalQuota > 0 {
                VStack(spacing: 8) {
                    Text("Today's Progress")
                        .font(.headline)
                    
                    HStack {
                        Text("\(totalSessions)/\(totalQuota)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("sessions used")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    ProgressView(value: Double(totalSessions), total: Double(totalQuota))
                        .tint(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "app.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Apps Added Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add apps to start managing your screen time with intentional sessions.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: QuotaListView()) {
                Text("Add Your First App")
                    .fontWeight(.medium)
                    .frame(width: 200, height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}