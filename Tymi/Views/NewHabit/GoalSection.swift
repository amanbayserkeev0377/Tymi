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
                    .frame(width: 26, height: 26)
                
                Text("Goal")
                    .font(.body.weight(.regular))
                
                Spacer()
                
                // Compact Type Selection
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
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
                        withAnimation(.easeInOut(duration: 0.3)) {
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
                    Spacer()
                    
                    let dateBinding = Binding<Date>(
                        get: {
                            let totalSeconds = Int(goal)
                            let hours = totalSeconds / 3600
                            let minutes = (totalSeconds % 3600) / 60
                            var components = DateComponents()
                            components.hour = hours
                            components.minute = minutes
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            let hours = components.hour ?? 0
                            let minutes = components.minute ?? 0
                            goal = Double(hours * 3600 + minutes * 60)
                        }
                    )
                    
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
