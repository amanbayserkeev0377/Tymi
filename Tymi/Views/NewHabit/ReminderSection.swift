import SwiftUI

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTime: Date
    
    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.primary)
                
                Text("Reminder")
                
                Spacer()
                
                if isReminderEnabled {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                Toggle("", isOn: $isReminderEnabled)
                    .labelsHidden()
                    .tint(.primary)
            }
            .frame(height: 44)
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
