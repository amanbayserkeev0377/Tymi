import SwiftUI

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTime: Date
    
    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 12) {
                Text("Reminder")
                
                Spacer()
                
                if isReminderEnabled {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .frame(width: 80)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                
                Toggle("", isOn: $isReminderEnabled)
                    .labelsHidden()
                    .tint(.primary)
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
