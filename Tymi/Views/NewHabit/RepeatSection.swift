import SwiftUI

enum RepeatType {
    case daily
    case weekly
}

struct RepeatSection: View {
    @Binding var selectedDays: Set<Int>
    @Binding var repeatType: RepeatType
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink {
            RepeatSettingsView(
                selectedDays: $selectedDays,
                repeatType: $repeatType
            )
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
            let days = selectedDays.sorted().map { dayNumberToString($0) }
            return days.isEmpty ? "Select days" : days.joined(separator: ", ")
        }
    }
    
    private func dayNumberToString(_ day: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        return formatter.shortWeekdaySymbols[day == 1 ? 6 : day - 2]
    }
}

struct RepeatSettingsView: View {
    @Binding var selectedDays: Set<Int>
    @Binding var repeatType: RepeatType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
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
    }
}

struct WeekdaySelectionView: View {
    @Binding var selectedDays: Set<Int>
    @Environment(\.dismiss) private var dismiss
    
    private let weekdays = [
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday"),
        (1, "Sunday")
    ]
    
    var body: some View {
        List {
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
        weekdays
            .filter { selectedDays.contains($0.0) }
            .map { $0.1 }
            .joined(separator: ", ")
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

