import SwiftUI

struct RepeatSection: View {
    @Binding var selectedDays: Set<Int>
    @Binding var repeatType: RepeatType
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink {
            Form {
                Button {
                    repeatType = .daily
                    selectedDays = Set(1...7)
                } label: {
                    HStack {
                        Text("Every day")
                        Spacer()
                        if repeatType == .daily {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                NavigationLink {
                    WeekdaySelectionView(selectedDays: $selectedDays)
                } label: {
                    HStack {
                        Text("Every week")
                        Spacer()
                        if repeatType == .weekly {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .onChange(of: selectedDays) { _ in
                    repeatType = .weekly
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack {
                Image(systemName: "repeat")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                Text("Repeat")
                Spacer()
                Text(repeatDescription)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var repeatDescription: String {
        switch repeatType {
        case .daily:
            return "Every day"
        case .weekly:
            let calendar = Calendar.current
            let firstWeekday = calendar.firstWeekday
            
            return selectedDays.sorted { day1, day2 in
                let adjustedDay1 = ((day1 - firstWeekday + 7) % 7)
                let adjustedDay2 = ((day2 - firstWeekday + 7) % 7)
                return adjustedDay1 < adjustedDay2
            }.map { dayNumberToString($0) }.joined(separator: ", ")
        }
    }
    
    private func dayNumberToString(_ day: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortWeekdaySymbols[day - 1]
    }
}

struct WeekdaySelectionView: View {
    @Binding var selectedDays: Set<Int>
    @Environment(\.dismiss) private var dismiss
    
    private var weekdays: [(Int, String)] {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday // 1 = Sunday, 2 = Monday, etc.
        
        return (0...6).map { offset in
            let day = ((firstWeekday - 1 + offset) % 7) + 1
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            let name = formatter.weekdaySymbols[day - 1]
            return (day, name)
        }
    }
    
    var body: some View {
        Form {
            ForEach(weekdays, id: \.0) { day, name in
                Button {
                    toggleDay(day)
                } label: {
                    HStack {
                        Text(name)
                        Spacer()
                        if selectedDays.contains(day) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            
            if !selectedDays.isEmpty {
                Section {
                    Text("Will repeat weekly on these days: \(selectedDaysDescription)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Repeat Weekly")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var selectedDaysDescription: String {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        
        return selectedDays.sorted { day1, day2 in
            let adjustedDay1 = ((day1 - firstWeekday + 7) % 7)
            let adjustedDay2 = ((day2 - firstWeekday + 7) % 7)
            return adjustedDay1 < adjustedDay2
        }.map { dayNumberToString($0) }.joined(separator: ", ")
    }
    
    private func dayNumberToString(_ day: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortWeekdaySymbols[day - 1]
    }
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            Section {
                RepeatSection(
                    selectedDays: .constant([2, 4, 6]),
                    repeatType: .constant(.weekly)
                )
            }
        }
    }
}

