import SwiftUI

struct GoalSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var goal: Double
    @Binding var type: HabitType
    let isCountFieldFocused: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "trophy")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                Text("Goal")
                    .font(.title3.weight(.semibold))
                
                Spacer()
                
                // Compact Type Selection
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            type = .count
                        }
                    } label: {
                        Image(systemName: "number")
                            .font(.body.weight(.medium))
                            .frame(width: 32, height: 32)
                            .background(type == .count ? Color.primary.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            type = .time
                        }
                    } label: {
                        Image(systemName: "clock")
                            .font(.body.weight(.medium))
                            .frame(width: 32, height: 32)
                            .background(type == .time ? Color.primary.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            if type == .count {
                TextField("Count", value: $goal, format: .number)
                    .keyboardType(.numberPad)
                    .font(.body.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .onTapGesture {
                        onTap()
                    }
            } else {
                HStack {
                    let dateBinding = Binding<Date>(
                        get: {
                            let totalMinutes = Int(goal)
                            let hours = totalMinutes / 60
                            let minutes = totalMinutes % 60
                            var components = DateComponents()
                            components.hour = hours
                            components.minute = minutes
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            let totalMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                            goal = Double(totalMinutes)
                        }
                    )
                    
                    TextField("Time", text: .constant(formatTime(minutes: Int(goal))))
                        .font(.body.weight(.medium))
                        .disabled(true)
                    
                    DatePicker(
                        "",
                        selection: dateBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .glassCard()
    }
    
    private func formatTime(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%dh %02dm", hours, mins)
    }
}

#Preview {
    GoalSection(
        goal: .constant(90),
        type: .constant(.time),
        isCountFieldFocused: true,
        onTap: {}
    )
    .padding()
}
