import SwiftUI

struct AppIconSection: View {
    @State private var selectedIcon: AppIcon = AppIconManager.shared.currentIcon
    
    var body: some View {
        NavigationLink {
            AppIconPickerView()
        } label: {
            HStack {
                Label("app_icon".localized, systemImage: "app")
                
                Spacer()
                
                Text(selectedIcon.displayName)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            selectedIcon = AppIconManager.shared.currentIcon
        }
    }
}
