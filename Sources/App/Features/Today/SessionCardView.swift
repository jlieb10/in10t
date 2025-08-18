import SwiftUI

struct SessionCardView: View {
    @EnvironmentObject var appState: AppState
    let quota: AppQuota
    
    @State private var showingSessionOptions = false
    @State private var isStartingSession = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    private var dailyUsage: DailyUsage {
        appState.getDailyUsage(for: quota.id)
    }
    
    private var isSessionActive: Bool {
        appState.sessionManager.isSessionActive(for: quota.id)
    }
    
    private var canStartSession: Bool {
        dailyUsage.sessionsUsed < quota.sessionsPerDay
    }
    
    private var progressPercentage: Double {
        guard quota.sessionsPerDay > 0 else { return 0 }
        return Double(dailyUsage.sessionsUsed) / Double(quota.sessionsPerDay)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quota.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if let intention = quota.intention, !intention.isEmpty {
                        Text(intention)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Session indicator
                sessionStatusIndicator
            }
            
            // Progress section
            if isSessionActive {
                activeSessionView
            } else {
                quotaProgressView
            }
            
            // Action button
            actionButton
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            updateTimeRemaining()
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionStarted)) { notification in
            if let appId = notification.object as? String, appId == quota.id {
                updateTimeRemaining()
                startTimer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionEnded)) { notification in
            if let appId = notification.object as? String, appId == quota.id {
                stopTimer()
            }
        }
    }
    
    private var sessionStatusIndicator: some View {
        Group {
            if isSessionActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            } else {
                HStack(spacing: 4) {
                    Text("\(dailyUsage.sessionsUsed)/\(quota.sessionsPerDay)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    // Dots indicator
                    HStack(spacing: 2) {
                        ForEach(0..<quota.sessionsPerDay, id: \.self) { index in
                            Circle()
                                .fill(index < dailyUsage.sessionsUsed ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
    }
    
    private var activeSessionView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Session Active")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(timeRemainingString)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .onReceive(timerService.$currentDate) { _ in
                        updateTimeRemaining()
                    }
            }
            
            ProgressView(value: 1 - (timeRemaining / quota.sessionDuration))
                .tint(.blue)
        }
    }
    
    private var quotaProgressView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Daily Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(quota.sessionMinutes)min sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progressPercentage)
                .tint(progressPercentage >= 1 ? .orange : .blue)
        }
    }
    
    private var actionButton: some View {
        Group {
            if isSessionActive {
                Button("End Session Early") {
                    endSession()
                }
                .buttonStyle(SecondaryActionButtonStyle())
            } else if canStartSession {
                Button(action: { showingSessionOptions = true }) {
                    Text("Start \(quota.sessionMinutes) min session")
                        .fontWeight(.medium)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(isStartingSession)
            } else {
                VStack(spacing: 8) {
                    Text("Daily limit reached")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text("Back tomorrow at midnight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .confirmationDialog("Start Session", isPresented: $showingSessionOptions) {
            Button("Start \(quota.sessionMinutes) min session") {
                startSession()
            }
            
            if let graceMinutes = quota.allowGraceMinutes,
               graceMinutes > 0,
               appState.authState.subscriptionStatus.isPro {
                Button("Start with +\(graceMinutes) min grace") {
                    startSessionWithGrace()
                }
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            if let intention = quota.intention, !intention.isEmpty {
                Text("Intention: \(intention)")
            } else {
                Text("Ready to start your session?")
            }
        }
    }
    
    private var timeRemainingString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    private func startSession() {
        isStartingSession = true
        
        Task {
            do {
                try await appState.sessionManager.startSession(for: quota, withGrace: false)
                await MainActor.run {
                    isStartingSession = false
                    updateTimeRemaining()
                    startTimer()
                }
            } catch {
                await MainActor.run {
                    isStartingSession = false
                    // Handle error - could show an alert
                }
            }
        }
    }
    
    private func startSessionWithGrace() {
        isStartingSession = true
        
        Task {
            do {
                try await appState.sessionManager.startSession(for: quota, withGrace: true)
                await MainActor.run {
                    isStartingSession = false
                    updateTimeRemaining()
                    startTimer()
                }
            } catch {
                await MainActor.run {
                    isStartingSession = false
                    // Handle error
                }
            }
        }
    }
    
    private func endSession() {
        appState.sessionManager.endSession(for: quota.id)
        stopTimer()
    }
    
    private func updateTimeRemaining() {
        timeRemaining = appState.sessionManager.timeRemaining(for: quota.id)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeRemaining()
            if timeRemaining <= 0 {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
    }
}

// MARK: - Button Styles

struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}