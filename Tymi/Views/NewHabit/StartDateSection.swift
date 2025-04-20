import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date

    var body: some View {
        Section {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(.primary)
            }
            .frame(height: 37)
        }
    }
}



#Preview {
    @Previewable @State var startDate = Date()
    
    return Form {
        StartDateSection(startDate: $startDate)
    }
}
