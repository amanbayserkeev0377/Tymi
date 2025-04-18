import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        Section {
            DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .tint(.primary)
        }
    }
}

#Preview {
    @Previewable @State var startDate = Date()
    
    return Form {
        StartDateSection(startDate: $startDate)
    }
}
