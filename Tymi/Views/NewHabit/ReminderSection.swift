import SwiftUI

struct ReminderSection: View {
    @Binding var reminder: Reminder
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .font(.body.weight(.medium))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .frame(width: 28, height: 28)
            
            Text("Reminder")
            
            Spacer()
            
            if reminder.isEnabled {
                DatePicker(
                    "",
                    selection: $reminder.time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
            }
            
            Toggle("", isOn: $reminder.isEnabled)
                .labelsHidden()
        }
    }
}

#Preview {
    Form {
        ReminderSection(
            reminder: .constant(Reminder(time: Date(), isEnabled: true))
        )
    }
}
