import StoreKit
import Foundation

/// Service for handling StoreKit 2 subscriptions and purchases
@MainActor
class StoreKitService: ObservableObject {
    @Published var subscriptionStatus: SubscriptionStatus = .free
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    
    private var updateListenerTask: Task<Void, Error>?
    
    private let productIDs = [
        Environment.monthlySubscriptionID,
        Environment.annualSubscriptionID
    ]
    
    func configure() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: productIDs)
            self.products = products.sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    // MARK: - Purchase Flow
    
    func purchaseSubscription(productId: String) async throws -> Bool {
        guard let product = products.first(where: { $0.id == productId }) else {
            throw StoreKitError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return true
            
        case .userCancelled:
            return false
            
        case .pending:
            throw StoreKitError.purchasePending
            
        @unknown default:
            throw StoreKitError.unknownResult
        }
    }
    
    func restorePurchases() async throws {
        for await result in Transaction.currentEntitlements {
            let transaction = try checkVerified(result)
            purchasedProductIDs.insert(transaction.productID)
        }
        
        await updateSubscriptionStatus()
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        var currentSubscription: SubscriptionStatus = .free
        var hasActiveSubscription = false
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Check if this is a subscription product
                if productIDs.contains(transaction.productID) {
                    // Check if subscription is still valid
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            hasActiveSubscription = true
                            
                            // Determine if it's trial or full subscription
                            if let introductoryOffer = transaction.offerID,
                               introductoryOffer.contains("trial") {
                                currentSubscription = .proTrial
                            } else {
                                currentSubscription = .pro
                            }
                        }
                    } else {
                        // Non-expiring subscription (shouldn't happen with our model)
                        hasActiveSubscription = true
                        currentSubscription = .pro
                    }
                }
                
                purchasedProductIDs.insert(transaction.productID)
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        if !hasActiveSubscription {
            currentSubscription = .free
            purchasedProductIDs.removeAll()
        }
        
        subscriptionStatus = currentSubscription
    }
    
    // MARK: - Transaction Listening
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                    
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    func product(for productId: String) -> Product? {
        return products.first { $0.id == productId }
    }
    
    func price(for productId: String) -> String {
        guard let product = product(for: productId) else { return "N/A" }
        return product.displayPrice
    }
    
    // MARK: - Subscription Info
    
    func getSubscriptionInfo() async -> SubscriptionInfo? {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if productIDs.contains(transaction.productID) {
                    return SubscriptionInfo(
                        productId: transaction.productID,
                        purchaseDate: transaction.purchaseDate,
                        expirationDate: transaction.expirationDate,
                        isActive: transaction.expirationDate?.timeIntervalSinceNow ?? 0 > 0
                    )
                }
            } catch {
                continue
            }
        }
        
        return nil
    }
    
    // MARK: - Cancellation (directs to App Store)
    
    func openSubscriptionManagement() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        Task {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to show subscription management: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

struct SubscriptionInfo {
    let productId: String
    let purchaseDate: Date
    let expirationDate: Date?
    let isActive: Bool
    
    var productName: String {
        switch productId {
        case Environment.monthlySubscriptionID:
            return "Intentional Pro Monthly"
        case Environment.annualSubscriptionID:
            return "Intentional Pro Annual"
        default:
            return "Unknown Subscription"
        }
    }
    
    var renewalDate: Date? {
        return expirationDate
    }
}

// MARK: - Errors

enum StoreKitError: LocalizedError {
    case productNotFound
    case purchasePending
    case failedVerification
    case unknownResult
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The requested product was not found."
        case .purchasePending:
            return "Purchase is pending approval."
        case .failedVerification:
            return "Purchase verification failed."
        case .unknownResult:
            return "An unknown error occurred during purchase."
        }
    }
}