import SwiftUI
import FamilyControls

struct OnboardingFlow: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var showingFamilyPicker = false
    
    let totalPages = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            TabView(selection: $currentPage) {
                WelcomeView()
                    .tag(0)
                
                PermissionRequestView(showingFamilyPicker: $showingFamilyPicker)
                    .tag(1)
                
                CompletionView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
        }
        .familyActivityPicker(
            isPresented: $showingFamilyPicker,
            selection: .constant(FamilyActivitySelection())
        ) { selection in
            handleAppSelection(selection)
        }
    }
    
    private func handleAppSelection(_ selection: FamilyActivitySelection) {
        let quotas = appState.familyControlsService.createAppQuotas(from: selection)
        for quota in quotas {
            appState.addAppQuota(quota)
        }
        
        if !quotas.isEmpty {
            currentPage = 2
        }
    }
}

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Welcome to Intentional")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Transform screen time into intentional moments with session-based app control.")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "timer.circle.fill",
                    title: "Time-boxed Sessions",
                    description: "Set specific durations for app usage"
                )
                
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    title: "Daily Quotas",
                    description: "Limit sessions per day to build healthy habits"
                )
                
                FeatureRow(
                    icon: "heart.circle.fill",
                    title: "Intention Setting",
                    description: "Define your purpose before each session"
                )
            }
            
            Spacer()
            
            Button("Get Started") {
                withAnimation {
                    // Move to next page - this would be handled by parent
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        }
        .padding()
    }
}

struct PermissionRequestView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingFamilyPicker: Bool
    @State private var isRequestingPermission = false
    @State private var permissionError: String?
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 16) {
                    Text("Screen Time Permission")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("We need permission to manage your selected apps. This enables session control and usage tracking.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                InfoRow(
                    icon: "lock.shield.fill",
                    text: "Your data stays private and secure on your device"
                )
                
                InfoRow(
                    icon: "eye.slash.fill",
                    text: "We never see what you do in your apps"
                )
                
                InfoRow(
                    icon: "gear.circle.fill",
                    text: "You can change these settings anytime"
                )
            }
            
            if let error = permissionError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: requestPermission) {
                    Group {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Grant Permission")
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isRequestingPermission)
                
                if appState.familyControlsService.isAuthorized {
                    Button("Choose Apps to Manage") {
                        showingFamilyPicker = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func requestPermission() {
        isRequestingPermission = true
        permissionError = nil
        
        Task {
            do {
                try await appState.familyControlsService.requestAuthorization()
                await MainActor.run {
                    isRequestingPermission = false
                }
            } catch {
                await MainActor.run {
                    permissionError = error.localizedDescription
                    isRequestingPermission = false
                }
            }
        }
    }
}

struct CompletionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Your intentional journey begins now. Start using your selected apps with mindful sessions.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            if !appState.appQuotas.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Apps You're Managing:")
                        .font(.headline)
                    
                    ForEach(appState.appQuotas) { quota in
                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundColor(.blue)
                            Text(quota.displayName)
                            Spacer()
                            Text("\(quota.sessionMinutes)min • \(quota.sessionsPerDay)x/day")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            Button("Start Using Intentional") {
                appState.completeOnboarding()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}