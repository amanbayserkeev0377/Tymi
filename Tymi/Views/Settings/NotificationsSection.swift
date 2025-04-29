import SwiftUI

struct NotificationsSection: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "bell.badge")
                .settingsIcon()
            
            Text("Notifications")
                .foregroundStyle(.primary)
            
            Spacer()
            
            Toggle("", isOn: $notificationsEnabled)
                .labelsHidden()
                .tint(colorScheme == .dark ? Color.white.opacity(0.7) : .black)
                .padding(.trailing)
        }
        .frame(height: 37)
    }
}

#Preview {
    NotificationsSection()
        .padding()
        .previewLayout(.sizeThatFits)
}
