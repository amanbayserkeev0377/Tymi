import SwiftUI

struct SettingsView: View {
    @AppStorage("firstWeekday") private var firstWeekday: Int = Calendar.current.firstWeekday
    @Binding var isPresented: Bool
    
    private let weekdayOptions = [
        (name: "System Default", value: Calendar.current.firstWeekday),
        (name: "Sunday", value: 1),
        (name: "Monday", value: 2)
    ]
    
    var body: some View {
        Form {
            Section {
                Picker("First Day of Week", selection: $firstWeekday) {
                    ForEach(weekdayOptions, id: \.value) { option in
                        Text(option.name).tag(option.value)
                    }
                }
            } header: {
                Text("Calendar")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(isPresented: .constant(true))
    }
}
