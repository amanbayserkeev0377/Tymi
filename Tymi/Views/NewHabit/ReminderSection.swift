import SwiftUI

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTimes: [Date]
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        Section {
            Toggle(isOn: $isReminderEnabled.animation()) {
                Label("reminders".localized, systemImage: "bell.badge.fill")
                    .symbolEffect(.bounce, options: .repeat(1), value: isReminderEnabled)
            }
            .tint(colorManager.selectedColor == .primary && colorScheme == .dark ? .gray.opacity(0.8) : colorManager.selectedColor.color)
            
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
                        
                        // Кнопка удаления напоминания (если их больше одного)
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
                
                // Кнопка добавления нового напоминания (ограничение до 5)
                if reminderTimes.count < 5 {
                    Button {
                        reminderTimes.append(Date())
                    } label: {
                        Label("add_reminder".localized, systemImage: "plus")
                    }
                }
            }
        }
    }
}
