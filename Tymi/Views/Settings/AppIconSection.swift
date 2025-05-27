import SwiftUI

struct AppIconSection: View {
    @State private var selectedIcon: AppIcon = AppIconManager.shared.currentIcon
    
    var body: some View {
        NavigationLink {
            AppIconPickerView()
        } label: {
            HStack {
                Label(
                    title: { Text("app_icon".localized) },
                    icon: {
                        Image(systemName: "app")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.4470588235, green: 0.5019607843, blue: 1, alpha: 1)),
                                Color(#colorLiteral(red: 0.1960784314, green: 0.2666666667, blue: 0.7333333333, alpha: 1))
                            ])
                    }
                )
                
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
