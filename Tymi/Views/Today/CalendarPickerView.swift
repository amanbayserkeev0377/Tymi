import SwiftUI

struct CalendarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    
    private var startDate: Date {
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        return thirtyDaysAgo
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemBackground)

    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок и описание
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Date")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(textColor)
                
                Text("Go back in time to see your progress for that day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Календарь
            DatePicker(
                "",
                selection: $selectedDate,
                in: startDate...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .tint(textColor)
            .padding(.horizontal)
            
            Spacer(minLength: 0)
        }
        .background(backgroundColor)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    CalendarPickerView(selectedDate: .constant(Date()))
} 
