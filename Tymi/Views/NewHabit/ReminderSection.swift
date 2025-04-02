import SwiftUI

struct ReminderSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isEnabled: Bool
    @Binding var time: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "bell")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                Text("Reminder")
                    .font(.title3.weight(.regular))
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if isEnabled {
                Divider()
                    .padding(.horizontal, 16)
                
                DatePicker(
                    "Time",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .glassCard()
        .animation(.easeInOut(duration: 0.3), value: isEnabled)
    }
}
