import SwiftUI

struct NotificationsSection: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "bell.badge")
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
            
            Text("Notifications")
                .foregroundStyle(.primary)
            
            Spacer()
            
            Toggle("", isOn: $notificationsEnabled)
                .labelsHidden()
                .tint(colorScheme == .dark ? Color.gray : .black)
        }
    }
}

#Preview {
    NotificationsSection()
        .padding()
        .previewLayout(.sizeThatFits)
}
