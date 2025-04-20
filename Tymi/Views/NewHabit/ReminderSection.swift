import SwiftUI

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTime: Date
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Section {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.primary)
                    .scaleEffect(isReminderEnabled ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isReminderEnabled)
                
                Text("Reminder")
                
                Spacer()
                
                if isReminderEnabled {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.primary)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
                }
                
                Toggle("", isOn: $isReminderEnabled.animation(.easeInOut(duration: 0.3)))
                    .labelsHidden()
                    .tint(colorScheme == .dark ? Color.white.opacity(0.7) : .black)
            }
            .frame(height: 37)
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
