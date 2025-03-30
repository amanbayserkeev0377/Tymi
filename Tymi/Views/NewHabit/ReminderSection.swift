import SwiftUI

struct ReminderSection: View {
    @Binding var isEnabled: Bool
    @Binding var time: Date
    @Environment(\.colorScheme) var colorScheme

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

                ZStack {
                    DatePicker("", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .opacity(0)

                    if isEnabled {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .frame(width: 100)

                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .tint(colorScheme == .light ? .black : Color.white.opacity(0.4))
            }
        }
        .padding(16)
        .glassCard()
        .animation(.easeOut(duration: 0.3), value: isEnabled)
    }
}
