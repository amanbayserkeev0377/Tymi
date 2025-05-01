import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date
    @Environment(\.colorScheme) private var colorScheme
    
    private let maxPastMonths = 12
    private let maxFutureDay = 0
    
    private var minDate: Date {
        Calendar.current.date(byAdding: .month, value: -maxPastMonths, to: Date()) ?? Date()
    }
    
    private var maxDate: Date {
        Calendar.current.date(byAdding: .day, value: maxFutureDay, to: Date()) ?? Date()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            DatePicker(
                "",
                selection: $selectedDate,
                in: minDate...maxDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.primary)
            .padding(.horizontal)
            .padding(.top, 20)
            
            Button(action: {
                selectedDate = Date()
            }) {
                Text("today".localized)
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? .black : .white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    CalendarView(selectedDate: .constant(Date()))
}
