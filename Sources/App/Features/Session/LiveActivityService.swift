import ActivityKit
import Foundation

/// Service for managing Live Activities (Dynamic Island and Lock Screen countdown)
class LiveActivityService: ObservableObject {
    static let shared = LiveActivityService()
    
    @Published var activeActivities: [String: Activity<SessionCountdownAttributes>] = [:]
    
    private init() {}
    
    // MARK: - Live Activity Management
    
    @available(iOS 16.1, *)
    func startSessionActivity(appName: String, duration: TimeInterval) async throws -> String {
        let attributes = SessionCountdownAttributes(appName: appName)
        let initialState = SessionCountdownAttributes.ContentState(
            endTime: Date().addingTimeInterval(duration),
            isGraceTime: false
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            
            let activityId = activity.id
            activeActivities[activityId] = activity
            
            return activityId
        } catch {
            throw LiveActivityError.failedToStart(error.localizedDescription)
        }
    }
    
    @available(iOS 16.1, *)
    func updateActivity(id: String, newEndTime: Date, isGraceTime: Bool = false) async {
        guard let activity = activeActivities[id] else { return }
        
        let newState = SessionCountdownAttributes.ContentState(
            endTime: newEndTime,
            isGraceTime: isGraceTime
        )
        
        do {
            try await activity.update(using: newState)
        } catch {
            print("Failed to update Live Activity: \(error)")
        }
    }
    
    @available(iOS 16.1, *)
    func endActivity(id: String, dismissalPolicy: ActivityUIDismissalPolicy = .default) {
        guard let activity = activeActivities[id] else { return }
        
        Task {
            await activity.end(dismissalPolicy: dismissalPolicy)
            activeActivities.removeValue(forKey: id)
        }
    }
    
    @available(iOS 16.1, *)
    func endAllActivities() {
        for (id, _) in activeActivities {
            endActivity(id: id)
        }
    }
    
    // MARK: - Activity Monitoring
    
    @available(iOS 16.1, *)
    func monitorActivityUpdates() {
        Task {
            for await activity in Activity<SessionCountdownAttributes>.activityUpdates {
                // Handle activity state changes
                switch activity.activityState {
                case .active:
                    activeActivities[activity.id] = activity
                case .ended, .dismissed:
                    activeActivities.removeValue(forKey: activity.id)
                case .stale:
                    // Activity is stale, might need to refresh
                    print("Live Activity became stale: \(activity.id)")
                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func isLiveActivityActive(for id: String) -> Bool {
        guard let activity = activeActivities[id] else { return false }
        return activity.activityState == .active
    }
    
    func getActiveActivityCount() -> Int {
        return activeActivities.count
    }
}

// MARK: - Live Activity Attributes

@available(iOS 16.1, *)
struct SessionCountdownAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let endTime: Date
        let isGraceTime: Bool
        
        var timeRemaining: TimeInterval {
            max(0, endTime.timeIntervalSinceNow)
        }
        
        var formattedTimeRemaining: String {
            let minutes = Int(timeRemaining) / 60
            let seconds = Int(timeRemaining) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        var isExpired: Bool {
            timeRemaining <= 0
        }
    }
    
    let appName: String
}

// MARK: - Live Activity Widget Views

@available(iOS 16.1, *)
struct SessionCountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionCountdownAttributes.self) { context in
            // Lock screen/banner UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                expandedView(context: context)
            } compactLeading: {
                // Compact leading UI
                Image(systemName: "hourglass.circle.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                // Compact trailing UI
                Text(context.state.formattedTimeRemaining)
                    .font(.caption2)
                    .fontWeight(.medium)
            } minimal: {
                // Minimal UI (when multiple activities are active)
                Image(systemName: "hourglass.circle.fill")
                    .foregroundColor(.blue)
            }
        }
    }
    
    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<SessionCountdownAttributes>) -> some View {
        HStack {
            Image(systemName: "hourglass.circle.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.appName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if context.state.isGraceTime {
                    Text("Grace time: \(context.state.formattedTimeRemaining)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                } else {
                    Text("Session: \(context.state.formattedTimeRemaining)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(context.state.formattedTimeRemaining)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(context.state.isGraceTime ? .orange : .blue)
        }
        .padding()
    }
    
    @ViewBuilder
    private func expandedView(context: ActivityViewContext<SessionCountdownAttributes>) -> some View {
        DynamicIslandExpandedRegion(.leading) {
            HStack {
                Image(systemName: "hourglass.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.appName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    if context.state.isGraceTime {
                        Text("Grace time")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Active session")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        
        DynamicIslandExpandedRegion(.trailing) {
            VStack {
                Text(context.state.formattedTimeRemaining)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(context.state.isGraceTime ? .orange : .blue)
                
                Text("remaining")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        
        DynamicIslandExpandedRegion(.bottom) {
            HStack {
                Spacer()
                
                // Progress bar
                ProgressView(value: 1 - (context.state.timeRemaining / 3600)) // Assuming max 1 hour
                    .progressViewStyle(LinearProgressViewStyle(tint: context.state.isGraceTime ? .orange : .blue))
                    .frame(height: 4)
                
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Errors

enum LiveActivityError: LocalizedError {
    case failedToStart(String)
    case failedToUpdate(String)
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .failedToStart(let reason):
            return "Failed to start Live Activity: \(reason)"
        case .failedToUpdate(let reason):
            return "Failed to update Live Activity: \(reason)"
        case .notSupported:
            return "Live Activities are not supported on this device."
        }
    }
}

// MARK: - Pre-iOS 16.1 Fallback

extension LiveActivityService {
    func startSessionActivityFallback(appName: String, duration: TimeInterval) -> String {
        // For devices without Live Activity support, we could:
        // - Schedule local notifications
        // - Update app badge
        // - Use other notification methods
        
        let notificationId = UUID().uuidString
        scheduleSessionNotifications(id: notificationId, appName: appName, duration: duration)
        return notificationId
    }
    
    private func scheduleSessionNotifications(id: String, appName: String, duration: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        
        // 50% warning
        let halfwayTime = duration * 0.5
        if halfwayTime > 60 { // Only if session is longer than 2 minutes
            let halfwayContent = UNMutableNotificationContent()
            halfwayContent.title = "\(appName) Session"
            halfwayContent.body = "Halfway through your session"
            halfwayContent.sound = .default
            
            let halfwayTrigger = UNTimeIntervalNotificationTrigger(timeInterval: halfwayTime, repeats: false)
            let halfwayRequest = UNNotificationRequest(identifier: "\(id)_halfway", content: halfwayContent, trigger: halfwayTrigger)
            
            center.add(halfwayRequest)
        }
        
        // 90% warning (2 minutes left or 10% remaining, whichever is less)
        let warningTime = duration - min(120, duration * 0.1)
        if warningTime > 0 && warningTime < duration - 10 {
            let warningContent = UNMutableNotificationContent()
            warningContent.title = "\(appName) Session Ending"
            warningContent.body = "Your session will end soon"
            warningContent.sound = .default
            
            let warningTrigger = UNTimeIntervalNotificationTrigger(timeInterval: warningTime, repeats: false)
            let warningRequest = UNNotificationRequest(identifier: "\(id)_warning", content: warningContent, trigger: warningTrigger)
            
            center.add(warningRequest)
        }
        
        // Session end
        let endContent = UNMutableNotificationContent()
        endContent.title = "\(appName) Session Complete"
        endContent.body = "Your session has ended"
        endContent.sound = .default
        
        let endTrigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let endRequest = UNNotificationRequest(identifier: "\(id)_end", content: endContent, trigger: endTrigger)
        
        center.add(endRequest)
    }
}