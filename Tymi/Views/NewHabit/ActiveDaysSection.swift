import SwiftUI

struct ActiveDaysSection: View {
    @Binding var activeDays: [Bool]
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    private var calendar: Calendar {
        return Calendar.userPreferred
    }
    
    private var activeDaysDescription: String {
        let allActive = activeDays.allSatisfy { $0 }
        
        if allActive {
            return "everyday".localized
        } else {
            return "every_week".localized
        }
    }
    
    var body: some View {
        NavigationLink(destination: ActiveDaysSelectionView(activeDays: $activeDays)) {
            HStack {
                Label("active_days".localized, systemImage: "cloud.sun")
                
                Spacer()
                
                Text(activeDaysDescription)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}

struct ActiveDaysSelectionView: View {
    @Binding var activeDays: [Bool]
    @Environment(\.dismiss) private var dismiss
    @Environment(WeekdayPreferences.self) private var weekdayPrefs
    
    private var calendar: Calendar {
        Calendar.userPreferred
    }
    
    private var weekdaySymbols: [String] {
        calendar.orderedFormattedFullWeekdaySymbols
    }
    
    private var selectedDaysDescription: String {
        let selectedDays = activeDays.enumerated()
            .filter { $0.element }
            .map { weekdaySymbols[$0.offset] }
            .joined(separator: ", ")
        
        return "will_repeat_weekly".localized + ": " + selectedDays
    }
    
    var body: some View {
        List {
            Section {
                Button {
                    withAnimation {
                        activeDays = Array(repeating: true, count: 7)
                    }
                } label: {
                    HStack {
                        Text("everyday".localized)
                        Spacer()
                        if activeDays.allSatisfy({ $0 }) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Section(header: Text("select_days".localized), footer: Text(selectedDaysDescription).font(.footnote)) {
                ForEach(0..<7) { index in
                    Button {
                        withAnimation {
                            activeDays[index].toggle()
                        }
                    } label: {
                        HStack {
                            Text(weekdaySymbols[index])
                            Spacer()
                            if activeDays[index] {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("active_days".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: activeDays) { oldValue, newValue in
            if newValue.allSatisfy({ !$0 }) {
                activeDays = oldValue
            }
        }
    }
}
