import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingSubscriptionManagement = false
    @State private var isExportingData = false
    @State private var exportedDataURL: URL?
    @State private var showingDataExport = false
    
    var body: some View {
        NavigationView {
            List {
                profileSection
                subscriptionSection
                dataSection
                supportSection
                accountSection
            }
            .navigationTitle("Settings")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out? Your data will be saved to the cloud.")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(dataURL: $exportedDataURL)
        }
    }
    
    private var profileSection: some View {
        Section("Profile") {
            if let profile = appState.authState.userProfile {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName ?? "User")
                            .font(.headline)
                        
                        if let email = profile.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(profile.subscriptionStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(profile.subscriptionStatus.isPro ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                            .foregroundColor(profile.subscriptionStatus.isPro ? .blue : .secondary)
                            .cornerRadius(6)
                        
                        Text("Since \(profile.creationDate.formatted(.dateTime.day().month().year()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var subscriptionSection: some View {
        Section("Subscription") {
            if appState.authState.subscriptionStatus.isPro {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Intentional Pro")
                    Spacer()
                    Text(appState.authState.subscriptionStatus == .proTrial ? "Trial" : "Active")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button("Manage Subscription") {
                    appState.storeKitService.openSubscriptionManagement()
                }
            } else {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("Upgrade to Pro")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Show paywall
                }
            }
        }
    }
    
    private var dataSection: some View {
        Section("Data & Privacy") {
            NavigationLink(destination: DataExportView(dataURL: $exportedDataURL)) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                    Text("Export Data")
                }
            }
            
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
                Text("Cloud Sync")
                Spacer()
                if let lastSync = appState.localStore.loadLastSyncDate() {
                    Text("Last: \(lastSync.formatted(.dateTime.day().month().hour().minute()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Sync Now") {
                Task {
                    await appState.syncWithCloud()
                }
            }
            .disabled(appState.isLoading)
            
            NavigationLink(destination: StorageInfoView()) {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.gray)
                    Text("Storage Info")
                }
            }
        }
    }
    
    private var supportSection: some View {
        Section("Support") {
            Link(destination: URL(string: "https://intentional.app/privacy")!) {
                HStack {
                    Image(systemName: "hand.raised")
                        .foregroundColor(.green)
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Link(destination: URL(string: "https://intentional.app/terms")!) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Link(destination: URL(string: "https://intentional.app/support")!) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.orange)
                    Text("Help & Support")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                Text("Version")
                Spacer()
                Text(AppVersion.displayVersion)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var accountSection: some View {
        Section("Account") {
            Button("Sign Out") {
                showingSignOutAlert = true
            }
            .foregroundColor(.orange)
            
            Button("Delete Account") {
                showingDeleteAccountAlert = true
            }
            .foregroundColor(.red)
        }
    }
    
    private func signOut() {
        Task {
            do {
                try await appState.authService.signOut()
                await MainActor.run {
                    appState.authState.signOut()
                }
            } catch {
                // Handle error
            }
        }
    }
    
    private func deleteAccount() {
        Task {
            do {
                // Delete from cloud
                if let userId = appState.authState.userProfile?.uid {
                    try await appState.cloudStore.deleteUserData(for: userId)
                }
                
                // Delete Firebase account
                try await appState.authService.deleteAccount()
                
                // Clear local data
                appState.localStore.clearUserData()
                
                await MainActor.run {
                    appState.authState.signOut()
                }
            } catch {
                // Handle error - show alert
            }
        }
    }
}

struct StorageInfoView: View {
    @EnvironmentObject var appState: AppState
    @State private var storageInfo: [String: Any] = [:]
    
    var body: some View {
        List {
            Section("Local Storage") {
                ForEach(Array(storageInfo.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key.capitalized)
                        Spacer()
                        Text("\(storageInfo[key] as? String ?? String(describing: storageInfo[key] ?? ""))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Actions") {
                Button("Clear Local Cache") {
                    // Clear non-essential local data
                    clearLocalCache()
                }
                .foregroundColor(.orange)
            }
        }
        .navigationTitle("Storage Info")
        .onAppear {
            loadStorageInfo()
        }
    }
    
    private func loadStorageInfo() {
        storageInfo = appState.localStore.getStorageInfo()
    }
    
    private func clearLocalCache() {
        // Implementation for clearing cache
        loadStorageInfo() // Refresh after clearing
    }
}

struct DataExportView: View {
    @EnvironmentObject var appState: AppState
    @Binding var dataURL: URL?
    @State private var isExporting = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Download all your session logs, app quotas, and usage statistics in JSON format.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    ExportItemRow(title: "App Quotas", description: "Your configured app limits and settings")
                    ExportItemRow(title: "Session Logs", description: "Complete history of your app usage sessions")
                    ExportItemRow(title: "Usage Statistics", description: "Daily usage summaries and streak data")
                    ExportItemRow(title: "Account Info", description: "Profile information and subscription status")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: exportData) {
                    Group {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Export Data")
                                .fontWeight(.medium)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isExporting)
                
                Text("Your data export will include all information stored locally and in the cloud.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = dataURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let exportData = appState.localStore.exportUserData() {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let exportURL = documentsPath.appendingPathComponent("intentional_data_export_\(Date().formatted(.iso8601.year().month().day())).json")
                
                do {
                    try exportData.write(to: exportURL)
                    
                    DispatchQueue.main.async {
                        dataURL = exportURL
                        isExporting = false
                        showingShareSheet = true
                    }
                } catch {
                    DispatchQueue.main.async {
                        isExporting = false
                        // Handle error
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isExporting = false
                    // Handle error
                }
            }
        }
    }
}

struct ExportItemRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}