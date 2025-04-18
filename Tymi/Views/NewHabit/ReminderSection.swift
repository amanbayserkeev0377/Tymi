import SwiftUI

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTime: Date
    
    var body: some View {
        Section {
            Toggle("Enable Reminder", isOn: $isReminderEnabled)
            
            if isReminderEnabled {
                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .padding(.vertical, 4)
            }
        } header: {
            Text("Reminder")
        } footer: {
            if isReminderEnabled {
                Text("You'll receive a notification at the selected time on active days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    @Previewable @State var isReminderEnabled = true
    @Previewable @State var reminderTime = Date()
    
    return Form {
        ReminderSection(
            isReminderEnabled: $isReminderEnabled,
            reminderTime: $reminderTime
        )
    }
}
