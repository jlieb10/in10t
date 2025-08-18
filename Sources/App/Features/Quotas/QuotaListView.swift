import SwiftUI
import FamilyControls

struct QuotaListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingFamilyPicker = false
    @State private var showingPaywall = false
    
    var body: some View {
        NavigationView {
            List {
                if appState.appQuotas.isEmpty {
                    emptyStateSection
                } else {
                    quotasSection
                }
                
                if appState.authState.subscriptionStatus == .free {
                    upgradeSection
                }
            }
            .navigationTitle("Managed Apps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addApp) {
                        Image(systemName: "plus")
                    }
                    .disabled(appState.authState.subscriptionStatus == .free && appState.appQuotas.count >= 1)
                }
            }
        }
        .familyActivityPicker(
            isPresented: $showingFamilyPicker,
            selection: .constant(FamilyActivitySelection())
        ) { selection in
            handleAppSelection(selection)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "app.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                
                Text("No Apps Added Yet")
                    .font(.headline)
                
                Text("Add apps to start managing your screen time with intentional sessions.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Add Your First App") {
                    addApp()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    private var quotasSection: some View {
        Section("Your Apps") {
            ForEach(appState.appQuotas) { quota in
                NavigationLink(destination: QuotaEditorView(quota: quota)) {
                    QuotaRowView(quota: quota)
                }
            }
            .onDelete(perform: deleteQuotas)
        }
    }
    
    private var upgradeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Upgrade to Pro")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                Text("• Unlimited apps\n• Custom session lengths\n• Grace time options\n• Cloud sync & backup")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("View Plans") {
                    showingPaywall = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func addApp() {
        // Check free tier limits
        if appState.authState.subscriptionStatus == .free && appState.appQuotas.count >= 1 {
            showingPaywall = true
            return
        }
        
        // Check Family Controls authorization
        guard appState.familyControlsService.isAuthorized else {
            // Request authorization first
            Task {
                do {
                    try await appState.familyControlsService.requestAuthorization()
                    await MainActor.run {
                        showingFamilyPicker = true
                    }
                } catch {
                    // Handle error
                }
            }
            return
        }
        
        showingFamilyPicker = true
    }
    
    private func handleAppSelection(_ selection: FamilyActivitySelection) {
        let newQuotas = appState.familyControlsService.createAppQuotas(from: selection)
        
        for quota in newQuotas {
            // Apply free tier restrictions
            var adjustedQuota = quota
            if appState.authState.subscriptionStatus == .free {
                adjustedQuota.sessionMinutes = 10
                adjustedQuota.sessionsPerDay = 1
                adjustedQuota.allowGraceMinutes = nil
            }
            
            appState.addAppQuota(adjustedQuota)
        }
        
        // Enable shields for new apps
        appState.familyControlsService.enableShields(for: newQuotas)
    }
    
    private func deleteQuotas(at offsets: IndexSet) {
        let quotasToRemove = offsets.map { appState.appQuotas[$0] }
        
        // Disable shields for removed apps
        appState.familyControlsService.disableShields(for: quotasToRemove)
        
        // Remove from app state
        for quota in quotasToRemove {
            appState.removeAppQuota(id: quota.id)
        }
    }
}

struct QuotaRowView: View {
    let quota: AppQuota
    @EnvironmentObject var appState: AppState
    
    private var dailyUsage: DailyUsage {
        appState.getDailyUsage(for: quota.id)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quota.displayName)
                    .font(.headline)
                
                if let intention = quota.intention, !intention.isEmpty {
                    Text(intention)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(quota.sessionMinutes)min • \(quota.sessionsPerDay)x/day")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text("\(dailyUsage.sessionsUsed)/\(quota.sessionsPerDay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Progress dots
                    HStack(spacing: 2) {
                        ForEach(0..<quota.sessionsPerDay, id: \.self) { index in
                            Circle()
                                .fill(index < dailyUsage.sessionsUsed ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .opacity(quota.isEnabled ? 1 : 0.6)
    }
}