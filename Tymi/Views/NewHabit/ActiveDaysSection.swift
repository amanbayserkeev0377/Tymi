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
                    withAnimation(.easeInOut) {
                        activeDays = Array(repeating: true, count: 7)
                    }
                } label: {
                    HStack {
                        Text("everyday".localized)
                            .tint(.primary)
                        Spacer()
                        Image(systemName: "checkmark")
                            .opacity(activeDays.allSatisfy({ $0 }) ? 1 : 0)
                            .animation(.easeInOut, value: activeDays.allSatisfy({ $0 }))
                    }
                }
            }
            
            Section(header: Text("select_days".localized), footer: Text(selectedDaysDescription).font(.footnote)) {
                ForEach(0..<7) { index in
                    Button {
                        withAnimation(.easeInOut) {
                            activeDays[index].toggle()
                        }
                    } label: {
                        HStack {
                            Text(weekdaySymbols[index])
                                .tint(.primary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .opacity(activeDays[index] ? 1 : 0)
                                .animation(.easeInOut, value: activeDays[index])
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
