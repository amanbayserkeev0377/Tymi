import SwiftUI

struct GoalSection: View {
    @Binding var goal: Double
    @Binding var type: HabitType
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink {
            GoalDetailView(goal: $goal, type: $type)
        } label: {
            HStack {
                Image(systemName: "trophy")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                Text("Daily Goal")
                Spacer()
                Text(type == .count ? String(format: "%.0f", goal) : formatTime(goal))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goal: Double
    @Binding var type: HabitType
    @State private var countText: String = ""
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    
    var body: some View {
        List {
            Section {
                Picker("Type", selection: $type) {
                    Text("Count").tag(HabitType.count)
                    Text("Time").tag(HabitType.time)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
                .onChange(of: type) { oldValue, newValue in
                    if oldValue == .count && newValue == .time {
                        // Конвертируем количество в минуты
                        goal = goal * 60
                    } else if oldValue == .time && newValue == .count {
                        // Конвертируем минуты в количество
                        goal = goal / 60
                    }
                    updateUI()
                }
            }
            
            Section {
                if type == .count {
                    TextField("Count", text: $countText)
                        .keyboardType(.numberPad)
                        .onChange(of: countText) { oldValue, newValue in
                            if let value = Double(newValue) {
                                goal = value
                            }
                        }
                        .onAppear {
                            countText = String(format: "%.0f", goal)
                        }
                } else {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                        
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0...59, id: \.self) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 100)
                    }
                    .onChange(of: hours) { oldValue, newValue in
                        updateGoal()
                    }
                    .onChange(of: minutes) { oldValue, newValue in
                        updateGoal()
                    }
                    .onAppear {
                        updateUI()
                    }
                }
            }
        }
        .navigationTitle("Daily Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func updateGoal() {
        goal = Double(hours * 3600 + minutes * 60)
    }
    
    private func updateUI() {
        if type == .count {
            countText = String(format: "%.0f", goal)
        } else {
            hours = Int(goal) / 3600
            minutes = Int(goal.truncatingRemainder(dividingBy: 3600)) / 60
        }
    }
}

#Preview {
    NavigationStack {
        GoalDetailView(goal: .constant(3600), type: .constant(.time))
    }
}
