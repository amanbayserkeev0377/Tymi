import SwiftUI

struct AppIconPickerView: View {
    @ObservedObject private var iconManager = AppIconManager.shared
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        List {
            ForEach(AppIcon.allIcons, id: \.id) { icon in
                iconRow(for: icon)
            }
        }
        .navigationTitle("choose_icon".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }
    
    // MARK: - Icon Row
    private func iconRow(for icon: AppIcon) -> some View {
        let isLocked = !proManager.isPro && icon.requiresPro
        
        return Button {
            if isLocked {
                showingPaywall = true
            } else {
                iconManager.setAppIcon(icon)
            }
        } label: {
            HStack {
                // Icon preview
                Image(icon.preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    .padding(.trailing, 8)
                    .opacity(isLocked ? 0.6 : 1.0)
                
                // Icon name
                Text(icon.displayName)
                    .font(.headline)
                    .foregroundStyle(isLocked ? .secondary : .primary)
                
                Spacer()
                
                // Right side - checkmark or lock
                if isLocked {
                    // Pro lock badge
                    ProLockBadge()
                } else if iconManager.currentIcon.id == icon.id {
                    // Selected checkmark
                    Image(systemName: "checkmark")
                        .withAppAccent()
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
