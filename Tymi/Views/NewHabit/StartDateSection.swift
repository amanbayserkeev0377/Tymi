import SwiftUI

struct StartDateSection: View {
    @Binding var date: Date
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.body.weight(.medium))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .frame(width: 28, height: 28)
            
            Text("Start Date")
            
            Spacer()
            
            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }
}

#Preview {
    Form {
        StartDateSection(date: .constant(Date()))
    }
}
