import SwiftUI

struct ReminderSection: View {
    @Binding var isReminderEnabled: Bool
    @Binding var reminderTimes: [Date]
    @State private var isAddingNewReminder = false
    @State private var newReminderTime = Date()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Section {
            // Основной тогл включения/выключения уведомлений
            Toggle(isOn: $isReminderEnabled.animation()) {
                Label {
                    Text("reminders".localized)
                } icon: {
                    Image(systemName: "bell.badge")
                        .symbolEffect(.bounce, options: .repeat(1), value: isReminderEnabled)
                }
            }
            .tint(colorScheme == .dark ? .gray.opacity(0.8) : .primary)
            
            if isReminderEnabled {
                // Список существующих напоминаний
                ForEach(0..<reminderTimes.count, id: \.self) { index in
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
                                reminderTimes.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                // Кнопка добавления нового напоминания (ограничение до 5)
                if reminderTimes.count < 5 {
                    Button {
                        isAddingNewReminder = true
                    } label: {
                        Label("add_reminder".localized, systemImage: "plus.circle")
                    }
                    .sheet(isPresented: $isAddingNewReminder) {
                        AddReminderView(
                            isPresented: $isAddingNewReminder,
                            reminderTime: $newReminderTime,
                            onSave: {
                                reminderTimes.append(newReminderTime)
                            }
                        )
                    }
                }
            }
        }
    }
}

// Вспомогательное представление для добавления нового напоминания
struct AddReminderView: View {
    @Binding var isPresented: Bool
    @Binding var reminderTime: Date
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                DatePicker(
                    "reminder_time".localized,
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 200)
            }
            .navigationTitle("add_reminder".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel".localized) {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("add".localized) {
                        onSave()
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
