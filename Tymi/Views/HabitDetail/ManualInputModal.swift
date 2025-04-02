import SwiftUI

struct ManualInputModal: View {
    let type: HabitType
    let currentValue: Double
    let onCancel: () -> Void
    let onAdd: (Double) -> Void
    
    @State private var countValue: String = ""
    @State private var selectedHours: Int = 0
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                
                Spacer()
                
                Text(type == .count ? "Enter Value" : "Set Time")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("Add") {
                    switch type {
                    case .count:
                        if let value = Double(countValue) {
                            onAdd(value)
                        }
                    case .time:
                        let totalSeconds = Double(selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds)
                        onAdd(totalSeconds)
                    }
                }
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Content
            if type == .count {
                TextField("Enter value", text: $countValue)
                    .font(.system(size: 48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 32)
            } else {
                HStack(spacing: 0) {
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(0...23, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    
                    Text("h")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach(0...59, id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    
                    Text("m")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                    
                    Picker("Seconds", selection: $selectedSeconds) {
                        ForEach(0...59, id: \.self) { second in
                            Text("\(second)").tag(second)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    
                    Text("s")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }
                .padding(.vertical, 32)
            }
        }
        .frame(width: UIScreen.main.bounds.width - 48)
        .glassCard()
    }
} 