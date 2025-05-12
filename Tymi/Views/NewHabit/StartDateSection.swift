import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.body)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)
            
            DatePicker(
                "start_date".localized,
                selection: $startDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
        }
    }
}
