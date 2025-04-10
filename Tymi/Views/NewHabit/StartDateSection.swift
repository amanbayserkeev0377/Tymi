import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationLink {
            StartDatePickerView(startDate: $startDate)
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Date")
                    Text(startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

struct StartDatePickerView: View {
    @Binding var startDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            DatePicker(
                "Start Date",
                selection: $startDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.vertical, 8)
        }
        .navigationTitle("Start Date")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        Form {
            Section {
                StartDateSection(startDate: .constant(Date()))
            }
        }
    }
}
