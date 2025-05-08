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
                .symbolEffect(.bounce, options: .repeat(1), value: notificationsEnabled)
            
            Text("notifications".localized)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Toggle("", isOn: $notificationsEnabled.animation(.easeInOut(duration: 0.3)))
                .labelsHidden()
                .tint(colorScheme == .dark ? Color.gray : .black)
                .onChange(of: notificationsEnabled) { _, newValue in
                    handleNotificationToggle(newValue)
                }
        }
        .alert("notification_permission".localized, isPresented: $isNotificationPermissionAlertPresented) {
            Button("cancel".localized, role: .cancel) { }
            Button("settings".localized) {
                openSettings()
            }
            
            Text("permission_for_notifications".localized)
        }
    }
    
    private func handleNotificationToggle(_ isEnabled: Bool) {
        if isEnabled {
            requestNotificationPermission()
        } else {
            NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            do {
                try await NotificationManager.shared.requestAuthorization()
                
                let isAuthorized = await NotificationManager.shared.checkNotificationStatus()
                
                await MainActor.run {
                    if isAuthorized {
                        NotificationManager.shared.updateAllNotifications(modelContext: modelContext)
                    } else {
                        notificationsEnabled = false
                        isNotificationPermissionAlertPresented = true
                    }
                }
            } catch {
                await MainActor.run {
                    notificationsEnabled = false
                    isNotificationPermissionAlertPresented = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
