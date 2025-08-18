import SwiftUI

struct QuotaEditorView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let quota: AppQuota
    @State private var editedQuota: AppQuota
    @State private var showingPaywall = false
    @State private var hasChanges = false
    
    private let sessionPresets = [5, 10, 15, 30]
    private let sessionsPresets = [1, 2, 3]
    
    init(quota: AppQuota) {
        self.quota = quota
        self._editedQuota = State(initialValue: quota)
    }
    
    var body: some View {
        NavigationView {
            Form {
                appSection
                sessionLengthSection
                sessionsPerDaySection
                intentionSection
                
                if appState.authState.subscriptionStatus.isPro {
                    graceTimeSection
                }
                
                advancedSection
            }
            .navigationTitle(quota.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!hasChanges)
                    .fontWeight(.medium)
                }
            }
        }
        .onChange(of: editedQuota) { _ in
            hasChanges = editedQuota != quota
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    private var appSection: some View {
        Section {
            HStack {
                Image(systemName: "app.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quota.displayName)
                        .font(.headline)
                    Text("App quota settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("Enabled", isOn: $editedQuota.isEnabled)
            }
        }
    }
    
    private var sessionLengthSection: some View {
        Section("Session Length") {
            if appState.authState.subscriptionStatus == .free {
                HStack {
                    Text("10 minutes")
                        .font(.headline)
                    Spacer()
                    Button("Upgrade to customize") {
                        showingPaywall = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                // Preset options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(sessionPresets, id: \.self) { preset in
                        Button(action: {
                            editedQuota.sessionMinutes = preset
                        }) {
                            Text("\(preset) min")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    editedQuota.sessionMinutes == preset ? Color.blue : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    editedQuota.sessionMinutes == preset ? .white : .primary
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Custom option
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(
                            value: Binding(
                                get: { Double(editedQuota.sessionMinutes) },
                                set: { editedQuota.sessionMinutes = Int($0) }
                            ),
                            in: 1...120,
                            step: 1
                        )
                        
                        Text("\(editedQuota.sessionMinutes) min")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 60)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var sessionsPerDaySection: some View {
        Section("Sessions Per Day") {
            if appState.authState.subscriptionStatus == .free {
                HStack {
                    Text("1 session")
                        .font(.headline)
                    Spacer()
                    Button("Upgrade for more") {
                        showingPaywall = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                // Preset options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(sessionsPresets, id: \.self) { preset in
                        Button(action: {
                            editedQuota.sessionsPerDay = preset
                        }) {
                            Text("\(preset)")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    editedQuota.sessionsPerDay == preset ? Color.blue : Color(.systemGray6)
                                )
                                .foregroundColor(
                                    editedQuota.sessionsPerDay == preset ? .white : .primary
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Custom option
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(
                            value: Binding(
                                get: { Double(editedQuota.sessionsPerDay) },
                                set: { editedQuota.sessionsPerDay = Int($0) }
                            ),
                            in: 1...10,
                            step: 1
                        )
                        
                        Text("\(editedQuota.sessionsPerDay)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(width: 30)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var intentionSection: some View {
        Section("Intention") {
            if appState.authState.subscriptionStatus == .free {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Relax mindfully")
                        .font(.body)
                    
                    Button("Upgrade to customize intentions") {
                        showingPaywall = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Enter your intention", text: Binding(
                        get: { editedQuota.intention ?? "" },
                        set: { editedQuota.intention = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    Text("Templates:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 8) {
                        ForEach(intentionTemplates, id: \.self) { template in
                            Button(template) {
                                editedQuota.intention = template
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
    
    private var graceTimeSection: some View {
        Section("Grace Time (Pro)") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Allow grace time", isOn: Binding(
                    get: { editedQuota.allowGraceMinutes != nil },
                    set: { enabled in
                        editedQuota.allowGraceMinutes = enabled ? 2 : nil
                    }
                ))
                
                if editedQuota.allowGraceMinutes != nil {
                    HStack {
                        Text("Grace minutes:")
                        Spacer()
                        Picker("Grace minutes", selection: Binding(
                            get: { editedQuota.allowGraceMinutes ?? 2 },
                            set: { editedQuota.allowGraceMinutes = $0 }
                        )) {
                            Text("2 minutes").tag(2)
                            Text("5 minutes").tag(5)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                }
            }
            
            Text("Grace time allows extending sessions when your daily quota isn't exhausted.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var advancedSection: some View {
        Section("Advanced") {
            Button("Reset Daily Usage", role: .destructive) {
                // Reset today's usage for this app
                var usage = appState.getDailyUsage(for: quota.id)
                usage.sessionsUsed = 0
                usage.secondsUsedThisSession = 0
                appState.updateDailyUsage(usage)
            }
        }
    }
    
    private let intentionTemplates = [
        "Relax mindfully for a few minutes",
        "Check for important updates only",
        "Connect with friends briefly",
        "Get inspired and motivated",
        "Learn something new"
    ]
    
    private func saveChanges() {
        appState.updateAppQuota(editedQuota)
        
        // Update shields if enabled state changed
        if quota.isEnabled != editedQuota.isEnabled {
            if editedQuota.isEnabled {
                appState.familyControlsService.enableShields(for: [editedQuota])
            } else {
                appState.familyControlsService.disableShields(for: [editedQuota])
            }
        }
        
        dismiss()
    }
}