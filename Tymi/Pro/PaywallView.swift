import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ProManager.self) private var proManager
    @ObservedObject private var colorManager = AppColorManager.shared
    
    @State private var selectedPackage: Package?
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPurchasing = false
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with laurels and app icon
                    headerSection
                    
                    // Features grid
                    featuresSection
                    
                    // Pricing options
                    if let offerings = proManager.offerings,
                       let currentOffering = offerings.current {
                        pricingSection(currentOffering)
                    }
                    
                    // Purchase button
                    purchaseButton
                    
                    // Restore and legal
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemBackground),
                        ProGradientColors.proAccentColor.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    XmarkView(action: {
                        dismiss()
                    })
                }
            }
        }
        .onAppear {
            selectDefaultPackage()
        }
        .alert("paywall_purchase_result_title".localized, isPresented: $showingAlert) {
            Button("button_ok") {
                if alertMessage.contains("successful") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Laurels with centered text
            HStack {
                Image(systemName: "laurel.leading")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradientSimple)
                
                Spacer()
                
                Text("paywall_header_title".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Image(systemName: "laurel.trailing")
                    .font(.system(size: 62))
                    .foregroundStyle(ProGradientColors.proGradientSimple)
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 20) {
            ForEach(ProFeature.allFeatures, id: \.id) { feature in
                FeatureRow(feature: feature)
            }
        }
    }
    
    // MARK: - Pricing Section
    private func pricingSection(_ offering: Offering) -> some View {
        VStack(spacing: 16) {
            ForEach(offering.availablePackages, id: \.identifier) { package in
                PricingCard(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    offering: offering
                ) {
                    selectedPackage = package
                    HapticManager.shared.playSelection()
                }
            }
        }
    }
    
    // MARK: - Purchase Button
        private var purchaseButton: some View {
            Button {
                purchaseSelected()
            } label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.9)
                            .tint(.white)
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                    }
                    
                    Text(buttonText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(ProGradientColors.proGradientSimple)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: ProGradientColors.proAccentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedPackage == nil || isPurchasing) // ИСПРАВИЛИ логику
            .opacity(selectedPackage == nil || isPurchasing ? 0.6 : 1.0)
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
    
    private var buttonText: String {
        if isLoading {
            return "paywall_processing_button".localized
        }
        
        guard let selectedPackage = selectedPackage else {
            return "paywall_subscribe_button".localized
        }
        
        if selectedPackage.packageType == .annual {
            return "paywall_start_free_trial_button".localized
        } else {
            return "paywall_subscribe_button".localized
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 20) {
            // Restore button
            Button("paywall_restore_purchases_button".localized) {
                restorePurchases()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            // Regional pricing notice
            Text("paywall_regional_pricing_notice".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 8)
            
            // Family Sharing button - ИСПРАВЛЕНО
            Button {
                if let url = URL(string: "https://www.apple.com/family-sharing/") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.subheadline)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue, Color.green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("paywall_family_sharing_button".localized)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            // Legal text
            Text("paywall_legal_text".localized)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // Terms and Privacy
            HStack(spacing: 30) {
                Button("paywall_terms_of_service_button".localized) {
                    // Open terms
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Button("paywall_privacy_policy_button".localized) {
                    // Open privacy policy
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectDefaultPackage() {
        guard let offerings = proManager.offerings,
              let currentOffering = offerings.current else { return }
        
        // Prefer yearly, fallback to monthly
        if let yearlyPackage = currentOffering.annual {
            selectedPackage = yearlyPackage
        } else if let monthlyPackage = currentOffering.monthly {
            selectedPackage = monthlyPackage
        } else if let firstPackage = currentOffering.availablePackages.first {
            selectedPackage = firstPackage
        }
    }
    
    private func purchaseSelected() {
            guard let package = selectedPackage, !isPurchasing else { return }
            
            isPurchasing = true
            isLoading = true
            HapticManager.shared.playImpact(.medium)
            
            Task {
                let success = await proManager.purchase(package: package)
                
                await MainActor.run {
                    isPurchasing = false
                    isLoading = false
                    
                    if success {
                        alertMessage = "paywall_purchase_success_message".localized
                        HapticManager.shared.play(.success)
                    } else {
                        alertMessage = "paywall_purchase_failed_message".localized
                        HapticManager.shared.play(.error)
                    }
                    showingAlert = true
                }
            }
        }
    
    private func restorePurchases() {
        isLoading = true
        
        Task {
            let success = await proManager.restorePurchases()
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    alertMessage = "paywall_restore_success_message".localized
                    HapticManager.shared.play(.success)
                } else {
                    alertMessage = "paywall_no_purchases_to_restore_message".localized
                }
                showingAlert = true
            }
        }
    }
}

// MARK: - Pro Feature Model
struct ProFeature {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let colors: [Color]
    
    static let allFeatures: [ProFeature] = [
        ProFeature(
            icon: "infinity",
            title: "paywall_unlimited_habits_title".localized,
            description: "paywall_unlimited_habits_description".localized,
            colors: [Color.orange, Color.yellow]
        ),
        ProFeature(
            icon: "folder.fill",
            title: "paywall_habit_folders_title".localized,
            description: "paywall_habit_folders_description".localized,
            colors: [Color.blue, Color.cyan]
        ),
        ProFeature(
            icon: "paintbrush.pointed.fill",
            title: "paywall_custom_colors_icons_title".localized,
            description: "paywall_custom_colors_icons_description".localized,
            colors: [Color.purple, Color.pink]
        ),
        ProFeature(
            icon: "heart.fill",
            title: "paywall_support_creator_title".localized,
            description: "paywall_support_creator_description".localized,
            colors: [Color.red, Color.orange]
        )
    ]
}

// MARK: - Feature Row
struct FeatureRow: View {
    let feature: ProFeature
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: feature.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let package: Package
    let isSelected: Bool
    let offering: Offering
    let onTap: () -> Void
    
    private var isMonthly: Bool {
        package.packageType == .monthly
    }
    
    private var isYearly: Bool {
        package.packageType == .annual
    }
    
    private var planName: String {
        isYearly ? "paywall_yearly_plan".localized : "paywall_monthly_plan".localized
    }
    
    private var priceText: String {
        let price = package.storeProduct.localizedPriceString
        return isYearly ? "\(price)/year" : "\(price)/month"
    }
    
    private var descriptionText: String {
        if isMonthly {
            return "paywall_monthly_description".localized
        } else {
            return "paywall_yearly_description".localized
        }
    }
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(planName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(descriptionText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(priceText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    if isYearly {
                        Text("paywall_free_trial_label".localized)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(ProGradientColors.proGradientSimple)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .background(cardShadow)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var strokeColor: Color {
        if isSelected {
            return ProGradientColors.proAccentColor
        } else {
            return Color(.separator)
        }
    }
    
    private var strokeWidth: CGFloat {
        isSelected ? 2.5 : 0.8
    }
    
    private var cardShadow: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clear)
                    .shadow(
                        color: ProGradientColors.proAccentColor.opacity(0.2),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
        }
    }
}
