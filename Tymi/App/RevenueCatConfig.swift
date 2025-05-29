import Foundation
import RevenueCat

struct RevenueCatConfig {
    // MARK: - API Keys
    static let apiKey = "appl_CsapRhmDoZzXsbFJoGxmhJGmKbS"
    
    // MARK: - Product Identifiers
    enum ProductIdentifiers {
        static let monthlySubscription = "com.amanbayserkeev.tymi.pro_monthly"
        static let yearlySubscription = "com.amanbayserkeev.tymi.pro_yearly"
        
        static let allProducts = [monthlySubscription, yearlySubscription]
    }
    
    // MARK: - Entitlements
    enum Entitlements {
        static let pro = "Tymi Pro Subscriptions"
    }
    
    // MARK: - Configuration
    static func configure() {
        // Configure RevenueCat
        Purchases.logLevel = .debug // Change to .error for production
        Purchases.configure(withAPIKey: apiKey)
        
        // Set user attributes if needed
        setUserAttributes()
    }
    
    private static func setUserAttributes() {
        // Example: Set user locale
        Purchases.shared.setAttributes(["locale": Locale.current.identifier])
    }
}

// MARK: - Pro Features Check
extension RevenueCatConfig {
    static func checkProStatus(completion: @escaping (Bool) -> Void) {
        Purchases.shared.getCustomerInfo { customerInfo, error in
            guard let customerInfo = customerInfo, error == nil else {
                completion(false)
                return
            }
            
            let hasPro = customerInfo.entitlements[Entitlements.pro]?.isActive == true
            completion(hasPro)
        }
    }
}
