import SwiftUI

struct ProSettingsSection: View {
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        Section {
            if !proManager.isPro {
                proPromoView
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Pro Promo View
    private var proPromoView: some View {
        Button {
            showingPaywall = true
        } label: {
            HStack(spacing: 16) {
                // Левая иконка
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                // Центральный контент
                VStack(alignment: .leading, spacing: 4) {
                    Text("Teymia Habit Pro")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("paywall_7_days_free_trial".localized)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Правая стрелочка
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ProGradientColors.proGradientSimple)
            )
        }
        .buttonStyle(.plain)
    }
}
