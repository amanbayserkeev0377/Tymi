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
                    .frame(width: 26, height: 26)
                
                Text("Reminder")
                    .font(.body.weight(.regular))
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(colorScheme == .dark ? Color(UIColor.systemGray6) : .black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if isEnabled {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack {
                    Spacer()
                    
                    DatePicker(
                        "Time",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8)),
                            removal: .opacity.combined(with: .offset(y: 8))
                        )
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .glassCard()
        .animation(.easeInOut(duration: 0.25), value: isEnabled)
    }
}
