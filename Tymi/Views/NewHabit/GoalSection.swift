import SwiftUI

struct GoalSection: View {
    @Binding var goal: String
    @Binding var type: HabitType
    @State private var isExpanded: Bool = false
    @State private var hours: Int = 1
    @State private var minutes: Int = 0
    @FocusState private var isCountFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
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
                                // Только цифры
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue {
                                    goal = filtered
                                }
                                // Убираем ведущие нули
                                if let number = Int(filtered), number > 0 {
                                    goal = String(number)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(Color.white.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
                            )
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button(action: {
                                        isCountFieldFocused = false
                                    }) {
                                        Image(systemName: "keyboard.chevron.compact.down")
                                            .foregroundStyle(.black)
                                            .imageScale(.large)
                                    }
                                }
                            }
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
