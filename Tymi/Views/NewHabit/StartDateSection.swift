import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    @State private var isCalendarExpanded: Bool = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Date Row
            Button(action :{
                withAnimation(.spring(response: 0.3)) {
                    isCalendarExpanded.toggle()
                }
            }) {
                HStack {
                    // Calendar Icon
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                    
                    Text("Start")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Date Text
                    Text(dateText)
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isCalendarExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isCalendarExpanded)
                }
            }
            .buttonStyle(.plain)
            
            // Calendar View
            if isCalendarExpanded {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(.black)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .glassCard()
        .animation(.easeInOut(duration: 0.3), value: isCalendarExpanded)
    }
    
    private var dateText: String {
        if calendar.isDateInToday(startDate) {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: startDate)
    }
}
