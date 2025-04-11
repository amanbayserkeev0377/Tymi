import SwiftUI

struct CalendarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    
    private var isDateSelectable: (Date) -> Bool {
        { date in
            let today = calendar.startOfDay(for: Date())
            return date <= today
        }
    }
    
    var body: some View {
        NavigationStack {
            DatePicker(
                "",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarPickerView(selectedDate: .constant(Date()))
} 