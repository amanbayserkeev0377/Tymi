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
                Text(type == .count ? String(Int(goal)) : String(format: "%.1f", goal))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goal: Double
    @Binding var type: HabitType
    
    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $type) {
                    Text("Count").tag(HabitType.count)
                    Text("Time").tag(HabitType.time)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section {
                if type == .count {
                    Stepper(value: $goal, in: 1...100, step: 1) {
                        HStack {
                            Text("Goal")
                            Spacer()
                            Text("\(Int(goal))")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Stepper(value: $goal, in: 0.5...180, step: 0.5) { // максимум 3 часа
                        HStack {
                            Text("Hours")
                            Spacer()
                            Text(String(format: "%.1f", goal))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Daily Goal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        Form {
            Section {
                GoalSection(goal: .constant(1.0), type: .constant(.count))
            }
        }
    }
}
