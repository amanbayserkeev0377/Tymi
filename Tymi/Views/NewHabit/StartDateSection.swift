import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        Section {
            DatePicker("Start tracking from", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.vertical, 4)
        } header: {
            Text("Start Date")
        } footer: {
            Text("Your habit tracking will begin on this date")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    @State var startDate = Date()
    
    return Form {
        StartDateSection(startDate: $startDate)
    }
}
