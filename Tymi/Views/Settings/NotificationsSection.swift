import SwiftUI
import SwiftData

struct NotificationsSection: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @Environment(\.modelContext) private var modelContext
    @State private var isNotificationPermissionAlertPresented = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Toggle(isOn: $notificationsEnabled.animation(.easeInOut(duration: 0.3))) {
            Label(
                title: { Text("notifications".localized) },
                icon: {
                    Image(systemName: "bell.badge")
                        .symbolEffect(.bounce, options: .repeat(1), value: notificationsEnabled)
                }
            )
        }
        .tint(colorScheme == .dark ? Color.gray.opacity(0.8) : .primary)
        .onChange(of: notificationsEnabled) { _, newValue in
            Task {
                await handleNotificationToggle(newValue)
            }
        }
        .alert("notification_permission".localized, isPresented: $isNotificationPermissionAlertPresented) {
            Button("cancel".localized, role: .cancel) { }
            Button("settings".localized) {
                openSettings()
            }
        } message: {
            Text("permission_for_notifications".localized)
        }
    }
    
    private func handleNotificationToggle(_ isEnabled: Bool) async {
        if isEnabled {
            // Пытаемся получить разрешения
            let isAuthorized = await NotificationManager.shared.ensureAuthorization()
            
            // Если нет разрешений, показываем диалог
            if !isAuthorized {
                notificationsEnabled = false
                isNotificationPermissionAlertPresented = true
            } else {
                // Обновляем уведомления
                NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
            }
        } else {
            // Просто обновляем настройки (что удалит все уведомления)
            NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
