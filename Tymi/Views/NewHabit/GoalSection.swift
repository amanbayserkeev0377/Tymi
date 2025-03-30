import SwiftUI

struct GoalSection: View {
    @Binding var goal: String
    @Binding var type: HabitType
    @FocusState.Binding var isCountFieldFocused: Bool
    @State private var isExpanded: Bool = false
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Goal Row
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                    if !isExpanded {
                        isCountFieldFocused = false
                    }
                }
            }) {
                HStack {
                    Image(systemName: "trophy")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                    
                    Text("Daily Goal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(goalText)
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 16) {
                    // Unit Selector
                    Picker("Type", selection: $type) {
                        Text("Count").tag(HabitType.count)
                        Text("Time").tag(HabitType.time)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 16)
                    .onChange(of: type) { _ in
                        isCountFieldFocused = false
                    }
                    
                    if type == .count {
                        // Count Input
                        TextField("Count", text: $goal)
                            .keyboardType(.numberPad)
                            .focused($isCountFieldFocused)
                            .onChange(of: goal) { newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    goal = filtered
                                }
                                if let number = Int(filtered), number > 0 {
                                    goal = String(number)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground).opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    } else {
                        // Time Pickers
                        HStack {
                            // Hours Picker
                            Picker("Hours", selection: $hours) {
                                ForEach(0...23, id: \.self) { hour in
                                    Text("\(hour)h").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 70)
                            .onChange(of: hours) { _ in
                                updateGoal()
                            }
                            
                            // Minutes Picker
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text("\(minute)m").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 70)
                            .onChange(of: minutes) { _ in
                                updateGoal()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .glassCard()
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
        .onChange(of: isCountFieldFocused) { isFocused in
            if !isFocused && goal.isEmpty {
                goal = "1"
            }
        }
    }
    
    private var goalText: String {
        if type == .count {
            return "\(goal) times"
        } else {
            if hours > 0 && minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else if hours > 0 {
                return "\(hours)h"
            } else {
                return "\(minutes)m"
            }
        }
    }
    
    private func updateGoal() {
        let totalMinutes = hours * 60 + minutes
        goal = String(totalMinutes)
    }
}
