import SwiftUI
import RevenueCat

@Observable @MainActor
class ProManager {
    static let shared = ProManager()
    
    private(set) var isPro: Bool = false
    private(set) var offerings: Offerings?
    private(set) var isLoading: Bool = false
    private init() {
        checkProStatus()
        loadOfferings()
    }
    
#if DEBUG
// MARK: - Debug Methods (только для тестирования)
@MainActor
func resetProStatusForTesting() {
    isPro = false
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
                let hasPro = customerInfo.entitlements[RevenueCatConfig.Entitlements.pro]?.isActive == true
                
                await MainActor.run {
                    self.isPro = hasPro
                    self.isLoading = false
                }
            } catch {
                print("❌ Error checking pro status: \(error)")
                await MainActor.run {
                    self.isPro = false
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
                let offerings = try await Purchases.shared.offerings()
                await MainActor.run {
                    self.offerings = offerings
                    self.isLoading = false
                }
                print("✅ Offerings loaded successfully")
            } catch {
                print("❌ Error loading offerings: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Purchase
    
    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let hasPro = result.customerInfo.entitlements[RevenueCatConfig.Entitlements.pro]?.isActive == true
            
            await MainActor.run {
                self.isPro = hasPro
            }
            
            return hasPro
        } catch {
            print("❌ Purchase error: \(error)")
            return false
        }
    }
    
    // MARK: - Restore
    
    func restorePurchases() async -> Bool {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let hasPro = customerInfo.entitlements[RevenueCatConfig.Entitlements.pro]?.isActive == true
            
            await MainActor.run {
                self.isPro = hasPro
            }
            
            return hasPro
        } catch {
            print("❌ Restore error: \(error)")
            return false
        }
    }
}

// MARK: - Pro Features
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
