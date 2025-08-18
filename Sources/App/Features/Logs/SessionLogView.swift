import SwiftUI

struct SessionLogView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTimeframe: Timeframe = .week
    @State private var selectedApp: String? = nil
    
    enum Timeframe: String, CaseIterable {
        case day = "Today"
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .all: return Int.max
            }
        }
    }
    
    private var filteredLogs: [SessionLog] {
        let allLogs = appState.localStore.loadSessionLogs()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeframe.days, to: Date()) ?? Date.distantPast
        
        var filtered = allLogs.filter { $0.start >= cutoffDate }
        
        if let selectedApp = selectedApp {
            filtered = filtered.filter { $0.appId == selectedApp }
        }
        
        return filtered.sorted { $0.start > $1.start }
    }
    
    private var totalSessionTime: TimeInterval {
        filteredLogs.reduce(0) { $0 + $1.actualDuration }
    }
    
    private var averageSessionTime: TimeInterval {
        guard !filteredLogs.isEmpty else { return 0 }
        return totalSessionTime / Double(filteredLogs.count)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters
                filtersSection
                
                // Statistics
                if !filteredLogs.isEmpty {
                    statisticsSection
                        .padding()
                        .background(Color(.systemGray6))
                }
                
                // Session list
                List {
                    if filteredLogs.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(groupedLogs, id: \.key) { dateGroup in
                            Section(dateGroup.key) {
                                ForEach(dateGroup.value) { log in
                                    SessionLogRow(log: log)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Session History")
        }
    }
    
    private var filtersSection: some View {
        VStack(spacing: 16) {
            // Timeframe picker
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
            
            // App filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: { selectedApp = nil }) {
                        FilterChip(
                            title: "All Apps",
                            isSelected: selectedApp == nil
                        )
                    }
                    
                    ForEach(appState.appQuotas) { quota in
                        Button(action: { selectedApp = quota.id }) {
                            FilterChip(
                                title: quota.displayName,
                                isSelected: selectedApp == quota.id
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var statisticsSection: some View {
        HStack(spacing: 0) {
            StatisticCard(
                title: "Total Sessions",
                value: "\(filteredLogs.count)",
                icon: "number.circle.fill",
                color: .blue
            )
            
            StatisticCard(
                title: "Total Time",
                value: formatDuration(totalSessionTime),
                icon: "clock.circle.fill",
                color: .green
            )
            
            StatisticCard(
                title: "Average Session",
                value: formatDuration(averageSessionTime),
                icon: "chart.bar.circle.fill",
                color: .orange
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Sessions Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Start using your managed apps to see session history here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private var groupedLogs: [(key: String, value: [SessionLog])] {
        let grouped = Dictionary(grouping: filteredLogs) { log in
            log.start.formatted(.dateTime.weekday(.wide).month().day())
        }
        
        return grouped.sorted { first, second in
            let firstDate = first.value.first?.start ?? Date.distantPast
            let secondDate = second.value.first?.start ?? Date.distantPast
            return firstDate > secondDate
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SessionLogRow: View {
    let log: SessionLog
    @EnvironmentObject var appState: AppState
    
    private var appQuota: AppQuota? {
        appState.appQuotas.first { $0.id == log.appId }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appQuota?.displayName ?? "Unknown App")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(log.start.formatted(.dateTime.hour().minute()))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let endTime = log.end {
                        Text("→ \(endTime.formatted(.dateTime.hour().minute()))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("(Active)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(log.actualDuration))
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    if log.startedViaShield {
                        Image(systemName: "shield.checkered")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text("\(log.quotaAtStart) of day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", seconds))"
        } else {
            return "0:\(String(format: "%02d", seconds))"
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}