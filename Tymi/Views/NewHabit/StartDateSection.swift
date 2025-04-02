import SwiftUI

struct StartDateSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var startDate: Date
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(startDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "calendar")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 26, height: 26)
                
                Text("Start Date")
                    .font(.body.weight(.regular))
                
                Spacer()
                
                DatePicker(
                    isToday ? "Today" : "Select Date",
                    selection: $startDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(.black)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .glassCard()
    }
}

#Preview {
    StartDateSection(startDate: .constant(Date()))
        .padding()
}
