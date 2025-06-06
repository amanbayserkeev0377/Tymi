import SwiftUI
import UserNotifications

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTimes: [Date]
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // Add alert state for permission request
    @State private var isNotificationPermissionAlertPresented = false
    
    var body: some View {
        Section {
            Toggle(isOn: $isReminderEnabled.animation()) {
                HStack {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(AppColorManager.shared.selectedColor.color)
                        .font(.system(size: 22))
                        .frame(width: 30)
                        .symbolEffect(.bounce, options: .repeat(1), value: isReminderEnabled)
                    Text("reminders".localized)
                }
            }
            .withToggleColor()
            .onChange(of: isReminderEnabled) { _, newValue in
                if newValue {
                    // Use unified permission handling through NotificationManager
                    Task {
                        await handleReminderToggle()
                    }
                }
            }
            
            if isReminderEnabled {
                ForEach(Array(reminderTimes.indices), id: \.self) { index in
                    HStack {
                        Text("reminder".localized + " \(index + 1)")
                        Spacer()
                        DatePicker(
                            "",
                            selection: $reminderTimes[index],
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        
                        // Remove reminder button (if more than one)
                        if reminderTimes.count > 1 {
                            Button {
                                if reminderTimes.indices.contains(index) {
                                    reminderTimes.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // Add new reminder button (limit to 5)
                if reminderTimes.count < 5 {
                    Button {
                        reminderTimes.append(Date())
                    } label: {
                        Label("add_reminder".localized, systemImage: "plus")
                    }
                }
            }
        }
        .alert("alert_notifications_permission".localized, isPresented: $isNotificationPermissionAlertPresented) {
            Button("button_cancel".localized, role: .cancel) { }
            Button("settings".localized) {
                openSettings()
            }
        } message: {
            Text("alert_notifications_permission_message".localized)
        }
    }
    
    // Handle reminder toggle using unified NotificationManager logic
    private func handleReminderToggle() async {
        // First enable notifications in app settings if not already enabled
        if !NotificationManager.shared.notificationsEnabled {
            NotificationManager.shared.notificationsEnabled = true
        }
        
        // Use NotificationManager's unified authorization logic
        let isAuthorized = await NotificationManager.shared.ensureAuthorization()
        
        await MainActor.run {
            if !isAuthorized {
                // Permission denied or unavailable - turn off toggle and show alert
                isReminderEnabled = false
                isNotificationPermissionAlertPresented = true
            }
            // If authorized, keep toggle on
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
