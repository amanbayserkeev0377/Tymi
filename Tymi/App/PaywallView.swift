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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    packagesSection
                    purchaseButton
                    restoreButton
                    legalSection
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Load offerings if not already loaded
            if proManager.offerings == nil {
                proManager.loadOfferings()
            }
            setupInitialSelection()
        }
        .alert("Purchase Result", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("TymiBlank")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            Text("Unlock Tymi Pro")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get unlimited habits and premium features")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(
                icon: "infinity",
                title: "Unlimited Habits",
                description: "Create as many habits as you need"
            )
            
            FeatureRow(
                icon: "bell.badge",
                title: "Multiple Reminders",
                description: "Set up to 5 reminders per habit"
            )
            
            FeatureRow(
                icon: "folder.fill",
                title: "Habit Folders",
                description: "Organize habits in custom folders"
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var packagesSection: some View {
        if proManager.isLoading || proManager.offerings == nil {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading packages...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
        } else if let offerings = proManager.offerings,
                  let currentOffering = offerings.current {
            VStack(spacing: 12) {
                ForEach(currentOffering.availablePackages, id: \.identifier) { package in
                    PackageView(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        offerings: offerings
                    ) {
                        selectedPackage = package
                    }
                }
            }
            .padding(.horizontal)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text("Unable to load packages")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Try Again") {
                    proManager.loadOfferings()
                }
                .foregroundStyle(colorManager.selectedColor.color)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var purchaseButton: some View {
        Button(action: purchaseSelected) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                Text(isLoading ? "Processing..." : "Start Tymi Pro")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(colorManager.selectedColor.color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(selectedPackage == nil || isLoading)
        .padding(.horizontal)
    }
    
    private var restoreButton: some View {
        Button("Restore Purchases") {
            restorePurchases()
        }
        .foregroundStyle(.secondary)
    }
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Terms of Service") {
                    // Open terms
                }
                
                Button("Privacy Policy") {
                    // Open privacy policy
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Methods
    
    private func setupInitialSelection() {
        guard let offerings = proManager.offerings,
              let currentOffering = offerings.current else { return }
        
        // Try to select yearly first, then monthly as fallback
        if let yearlyPackage = currentOffering.annual {
            selectedPackage = yearlyPackage
        } else if let monthlyPackage = currentOffering.monthly {
            selectedPackage = monthlyPackage
        }
    }
    
    private func purchaseSelected() {
        guard let package = selectedPackage else { return }
        
        isLoading = true
        
        Task {
            let success = await proManager.purchase(package: package)
            
            await MainActor.run {
                isLoading = false
                
                if success {
                    alertMessage = "Purchase successful! Tymi Pro features are now available."
                    showingAlert = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                } else {
                    alertMessage = "Purchase failed. Please try again."
                    showingAlert = true
                }
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
                    alertMessage = "Purchases restored successfully!"
                    showingAlert = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                } else {
                    alertMessage = "No purchases to restore."
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColorManager.shared.selectedColor.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Package View

struct PackageView: View {
    let package: Package
    let isSelected: Bool
    let offerings: Offerings?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            packageContent
        }
        .buttonStyle(.plain)
    }
    
    private var packageContent: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.storeProduct.localizedTitle)
                        .font(.headline)
                    
                    if !package.storeProduct.localizedDescription.isEmpty {
                        Text(package.storeProduct.localizedDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text(package.storeProduct.localizedPriceString)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppColorManager.shared.selectedColor.color.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? AppColorManager.shared.selectedColor.color : Color.clear,
                        lineWidth: 2
                    )
            )
        }
    }
}
