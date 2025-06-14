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
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
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
