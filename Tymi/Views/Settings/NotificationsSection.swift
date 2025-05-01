import SwiftUI
import SwiftData

struct NotificationsSection: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var isNotificationPermissionAlertPresented = false
    
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
                .onChange(of: notificationsEnabled) { newValue in
                    if newValue {
                        Task {
                            do {
                                try await NotificationManager.shared.requestAuthorization()
                                NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
                            } catch {
                                notificationsEnabled = false
                                isNotificationPermissionAlertPresented = true
                            }
                        }
                    } else {
                        NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
                    }
                }
        }
        .alert("notification_permission".localized, isPresented: $isNotificationPermissionAlertPresented) {
            Button("cancel".localized, role: .cancel) { }
            Button("settings".localized) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("permission_for_notifications".localized)
        }
    }
}
