import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        DatePicker(
            "start_date".localized,
            selection: $startDate,
            in: ...Date(),
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
    }
}
