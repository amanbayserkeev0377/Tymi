import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        HStack {
            Label("start_date".localized, systemImage: "calendar.badge.clock")
            
            Spacer()
            
            DatePicker(
                "",
                selection: $startDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }
}
