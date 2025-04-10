import SwiftUI

struct ReminderSection: View {
    @Binding var reminders: [Reminder]
    @State private var showingTimePicker = false
    @State private var selectedTime = Date()
    
    var body: some View {
        NavigationLink {
            List {
                Section {
                    ForEach(reminders) { reminder in
                        HStack {
                            Toggle(isOn: binding(for: reminder)) {
                                Text(reminder.time.formatted(date: .omitted, time: .shortened))
                            }
                        }
                    }
                    .onDelete(perform: deleteReminder)
                }
                
                Section {
                    Button(action: { showingTimePicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add Reminder")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTimePicker) {
                NavigationStack {
                    DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .navigationTitle("Add Reminder")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    showingTimePicker = false
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Add") {
                                    addReminder()
                                    showingTimePicker = false
                                }
                            }
                        }
                }
                .presentationDetents([.height(300)])
            }
        } label: {
            HStack {
                Text("Reminders")
                Spacer()
                if reminders.isEmpty {
                    Text("None")
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(reminders.count) Active")
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
    }
    
    private func binding(for reminder: Reminder) -> Binding<Bool> {
        Binding(
            get: { reminder.isEnabled },
            set: { newValue in
                if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                    reminders[index].isEnabled = newValue
                }
            }
        )
    }
    
    private func deleteReminder(at offsets: IndexSet) {
        reminders.remove(atOffsets: offsets)
    }
    
    private func addReminder() {
        let reminder = Reminder(time: selectedTime)
        reminders.append(reminder)
        reminders.sort { $0.time < $1.time }
    }
}

#Preview {
    NavigationStack {
        Form {
            ReminderSection(reminders: .constant([
                Reminder(time: Date()),
                Reminder(time: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
            ]))
        }
    }
}
