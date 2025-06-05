import SwiftUI
import RevenueCat

@Observable @MainActor
class ProManager {
    static let shared = ProManager()
    
    private(set) var isPro: Bool = false
    private(set) var offerings: Offerings?
    private(set) var isLoading: Bool = false
    
    // MARK: - New: Track purchase type
    private(set) var hasLifetimePurchase: Bool = false
    private(set) var hasActiveSubscription: Bool = false
    
    private init() {
        checkProStatus()
        loadOfferings()
    }
    
#if DEBUG
// MARK: - Debug Methods (только для тестирования)
@MainActor
func resetProStatusForTesting() {
    isPro = false
    hasLifetimePurchase = false
    hasActiveSubscription = false
    print("🧪 Pro status reset for testing")
}

@MainActor
func setProStatusForTesting(_ status: Bool) {
    isPro = status
    print("🧪 Pro status set to: \(status)")
}

func toggleProStatusForTesting() {
    Task { @MainActor in
        isPro.toggle()
        print("🧪 Pro status toggled to: \(isPro)")
    }
}
#endif
    
    // MARK: - Pro Status
    
    func checkProStatus() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                await updateProStatusFromCustomerInfo(customerInfo)
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                print("✅ Pro status checked - isPro: \(isPro), subscription: \(hasActiveSubscription), lifetime: \(hasLifetimePurchase)")
                
            } catch {
                print("❌ Error checking pro status: \(error)")
                await MainActor.run {
                    self.isPro = false
                    self.hasActiveSubscription = false
                    self.hasLifetimePurchase = false
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Offerings
    func loadOfferings() {
        Task {
            await MainActor.run {
                isLoading = true
            }
            
            do {
                // КРИТИЧНО: Добавляем таймаут для Apple Review
                let offerings = try await withTimeout(seconds: 8) {
                    try await Purchases.shared.offerings()
                }
                
                await MainActor.run {
                    self.offerings = offerings
                    self.isLoading = false
                }
                
                print("✅ Offerings loaded: \(offerings.current?.availablePackages.count ?? 0) packages")
                
            } catch {
                print("❌ Offerings timeout or error: \(error)")
                
                await MainActor.run {
                    // Принудительно останавливаем загрузку после таймаута
                    self.offerings = nil
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Purchase
    
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            // Re-check status after purchase
            await updateProStatusFromCustomerInfo(result.customerInfo)
            
            return isPro
        } catch {
            print("❌ Purchase error: \(error)")
            return false
        }
    }
    
    // MARK: - Purchase Lifetime (separate method for clarity)
    func purchaseLifetime() async -> Bool {
        // Get lifetime package from offerings
        guard let offerings = offerings,
              let lifetimePackage = findLifetimePackage(in: offerings) else {
            print("❌ Lifetime package not found in offerings")
            return false
        }
        
        return await purchase(package: lifetimePackage)
    }
    
    // MARK: - Restore
    
    func restorePurchases() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            await updateProStatusFromCustomerInfo(customerInfo)
            return isPro
        } catch {
            print("❌ Restore error: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    private func updateProStatusFromCustomerInfo(_ customerInfo: CustomerInfo) async {
        // Check subscription entitlement
        let hasActiveEntitlement = customerInfo.entitlements[RevenueCatConfig.Entitlements.pro]?.isActive == true
        
        // Check lifetime purchase (Non-Consumable)
        let hasLifetime = customerInfo.nonSubscriptions.contains { nonSub in
            nonSub.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
        }
        
        // User has Pro if they have either active subscription OR lifetime purchase
        let hasPro = hasActiveEntitlement || hasLifetime
        
        await MainActor.run {
            self.isPro = hasPro
            self.hasActiveSubscription = hasActiveEntitlement
            self.hasLifetimePurchase = hasLifetime
        }
    }
    
    // MARK: - Public method to find lifetime package
    func findLifetimePackage(in offerings: Offerings) -> Package? {
        // Look for lifetime in current offering
        if let lifetimePackage = offerings.current?.availablePackages.first(where: {
            $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
        }) {
            return lifetimePackage
        }
        
        // Look in all offerings if not in current
        for offering in offerings.all.values {
            if let lifetimePackage = offering.availablePackages.first(where: {
                $0.storeProduct.productIdentifier == RevenueCatConfig.ProductIdentifiers.lifetimePurchase
            }) {
                return lifetimePackage
            }
        }
        
        return nil
    }
}

// MARK: - Pro Features (unchanged)
extension ProManager {
    var maxHabitsCount: Int {
        isPro ? Int.max : 3
    }
    
    var canUseAdvancedFeatures: Bool {
        isPro
    }
    
    var canUseMultipleReminders: Bool {
        isPro
    }
    
    var canUseFolders: Bool {
        isPro
    }
}

struct TimeoutError: Error {}
