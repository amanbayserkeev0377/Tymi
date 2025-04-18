import SwiftUI

struct ActiveDaysSection: View {
    @Binding var activeDays: [Bool]
    
    // Calendar for day names
    private let calendar = Calendar.current
    
    // Day symbols
    private var daySymbols: [String] {
        var symbols = calendar.shortWeekdaySymbols
        
        // Rearrange symbols based on first day of week
        let firstWeekday = calendar.firstWeekday - 1
        let before = Array(symbols[firstWeekday...])
        let after = Array(symbols[..<firstWeekday])
        return before + after
    }
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                // Quick selection buttons
                HStack {
                    Button("All") {
                        activeDays = Array(repeating: true, count: 7)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Weekdays") {
                        // Set weekdays based on locale and calendar settings
                        var weekdaysDays = Array(repeating: false, count: 7)
                        for i in 0..<7 {
                            let adjustedIndex = (i + calendar.firstWeekday - 1) % 7
                            // In Gregorian calendar, 2-6 are weekdays
                            weekdaysDays[i] = (adjustedIndex + 1) >= 2 && (adjustedIndex + 1) <= 6
                        }
                        activeDays = weekdaysDays
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Weekends") {
                        // Set weekends based on locale and calendar settings
                        var weekendDays = Array(repeating: false, count: 7)
                        for i in 0..<7 {
                            let adjustedIndex = (i + calendar.firstWeekday - 1) % 7
                            // In Gregorian calendar, 1 and 7 are weekend
                            weekendDays[i] = (adjustedIndex + 1) == 1 || (adjustedIndex + 1) == 7
                        }
                        activeDays = weekendDays
                    }
                    .buttonStyle(.bordered)
                    
                    Button("None") {
                        activeDays = Array(repeating: false, count: 7)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
                
                // Day selection circles
                HStack {
                    ForEach(0..<7) { index in
                        VStack {
                            Text(daySymbols[index].prefix(1))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ZStack {
                                Circle()
                                    .fill(activeDays[index] ? Color.blue : Color.gray.opacity(0.2))
                                    .frame(width: 36, height: 36)
                                
                                if !activeDays[index] {
                                    Circle()
                                        .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
                                        .frame(width: 36, height: 36)
                                }
                            }
                            .onTapGesture {
                                activeDays[index].toggle()
                            }
                        }
                        
                        if index < 6 {
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Active Days")
        }
    }
}

#Preview {
    @State var activeDays = Array(repeating: true, count: 7)
    
    return Form {
        ActiveDaysSection(activeDays: $activeDays)
    }
}
