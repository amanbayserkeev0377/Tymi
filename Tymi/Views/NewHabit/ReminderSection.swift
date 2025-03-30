import SwiftUI

struct ReminderSection: View {
    @Binding var isEnabled: Bool
    @Binding var time: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                
                Text("Reminder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isEnabled {
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(.black)
            }
        }
        .padding(16)
        .glassCard()
        .animation(.easeOut(duration: 0.3), value: isEnabled)
    }
}
