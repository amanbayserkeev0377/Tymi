import SwiftUI

enum ChartTimeRange: String, CaseIterable {
    case week = "W"
    case month = "M"
    case year = "Y"
    
    var localized: String {
        switch self {
        case .week: return "W"
        case .month: return "M"
        case .year: return "Y"
        }
    }
    
    var days: Int {
        let calendar = Calendar.current
        switch self {
        case .week: return 7
        case .month: 
            let range = calendar.range(of: .day, in: .month, for: Date())
            return range?.count ?? 30
        case .year: return 365 // Тоже стоит сделать динамически
        }
    }
}

struct TimeRangePicker: View {
    @Binding var selection: ChartTimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selection) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in 
                Text(range.localized).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}
