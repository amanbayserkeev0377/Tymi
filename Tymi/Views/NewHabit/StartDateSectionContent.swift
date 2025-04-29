import SwiftUI

struct StartDateSectionContent: View {
    @Binding var startDate: Date

    var body: some View {
        Section {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)
                
                Text("Start Date")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .tint(.primary)
                    .labelsHidden()
            }
            .frame(height: 37)
        }
    }
}



#Preview {
    @Previewable @State var startDate = Date()
    
    return Form {
        StartDateSectionContent(startDate: $startDate)
    }
}
