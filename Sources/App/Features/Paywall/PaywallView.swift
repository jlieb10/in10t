import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    enum SubscriptionPlan: CaseIterable {
        case monthly, annual
        
        var productId: String {
            switch self {
            case .monthly:
                return Environment.monthlySubscriptionID
            case .annual:
                return Environment.annualSubscriptionID
            }
        }
        
        var displayName: String {
            switch self {
            case .monthly:
                return "Monthly"
            case .annual:
                return "Annual"
            }
        }
        
        var price: String {
            switch self {
            case .monthly:
                return "£4.99/month"
            case .annual:
                return "£29.99/year"
            }
        }
        
        var savings: String? {
            switch self {
            case .monthly:
                return nil
            case .annual:
                return "Save £30"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerView
                    
                    // Features
                    featuresView
                    
                    // Pricing
                    pricingView
                    
                    // CTA
                    ctaView
                    
                    // Free option
                    freeOptionView
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Make Screen Time Intentional")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Transform your relationship with technology through mindful, session-based app usage.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var featuresView: some View {
        VStack(spacing: 20) {
            FeatureCard(
                icon: "infinity.circle.fill",
                iconColor: .blue,
                title: "Unlimited Apps",
                description: "Manage as many apps as you need"
            )
            
            FeatureCard(
                icon: "timer.circle.fill",
                iconColor: .green,
                title: "Custom Session Times",
                description: "Set any duration from 1-120 minutes"
            )
            
            FeatureCard(
                icon: "plus.circle.fill",
                iconColor: .orange,
                title: "Grace Time",
                description: "Add extra minutes when needed"
            )
            
            FeatureCard(
                icon: "flame.circle.fill",
                iconColor: .red,
                title: "Advanced Streaks",
                description: "Detailed progress tracking & badges"
            )
            
            FeatureCard(
                icon: "icloud.circle.fill",
                iconColor: .purple,
                title: "Cloud Sync",
                description: "Your data syncs across devices"
            )
            
            FeatureCard(
                icon: "widget.small.fill",
                iconColor: .pink,
                title: "Widgets & Shortcuts",
                description: "Home screen widgets and Siri integration"
            )
        }
    }
    
    private var pricingView: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                    PricingCard(
                        plan: plan,
                        isSelected: selectedPlan == plan,
                        action: { selectedPlan = plan }
                    )
                }
            }
            
            Text("7-day free trial • Cancel anytime")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var ctaView: some View {
        VStack(spacing: 12) {
            Button(action: startFreeTrial) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Start 7-Day Free Trial")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var freeOptionView: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            VStack(spacing: 8) {
                Text("Continue with Free")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("• 1 app only\n• 10-minute sessions\n• 1 session per day")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Continue Free") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(8)
        }
    }
    
    private func startFreeTrial() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await appState.storeKitService.purchaseSubscription(productId: selectedPlan.productId)
                
                await MainActor.run {
                    if success {
                        // Update subscription status
                        if var profile = appState.authState.userProfile {
                            profile.subscriptionStatus = .proTrial
                            appState.authState.signIn(with: profile)
                        }
                        dismiss()
                    } else {
                        errorMessage = "Purchase was cancelled or failed"
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PricingCard: View {
    let plan: PaywallView.SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(plan.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(plan.price)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let savings = plan.savings {
                    Text(savings)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}