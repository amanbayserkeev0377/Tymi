import SwiftUI

struct GoalSection: View {
    @Binding var goal: Double
    @State private var showingGoalDetail = false
    
    var body: some View {
        NavigationLink {
            GoalDetailView(goal: $goal)
        } label: {
            HStack {
                Text("Daily Goal")
                Spacer()
                Text(String(format: "%.1f", goal))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var goal: Double
    @State private var selectedType: GoalType = .count
    
    private enum GoalType: String, CaseIterable {
        case count = "Count"
        case duration = "Duration"
        case distance = "Distance"
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $selectedType) {
                    ForEach(GoalType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)
            }
            
            Section {
                Stepper(value: $goal, in: 0.5...100, step: 0.5) {
                    HStack {
                        Text("Goal")
                        Spacer()
                        Text(String(format: "%.1f", goal))
                            .foregroundStyle(.secondary)
                    }
                }
                
                if selectedType == .duration {
                    DatePicker("Time", selection: .constant(Date()), displayedComponents: .hourAndMinute)
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
                GoalSection(goal: .constant(1.0))
            }
        }
    }
}
