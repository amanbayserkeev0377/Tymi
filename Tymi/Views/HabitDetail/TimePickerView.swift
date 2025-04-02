import SwiftUI

struct TimePickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var seconds: Int = 0
    let onSave: (Double) -> Void
    
    private let hourRange = 0...23
    private let minuteRange = 0...59
    private let secondRange = 0...59
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Content
            VStack(spacing: 24) {
                Text("Set Time")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 0) {
                    // Hours
                    pickerWheel(
                        value: $hours,
                        range: hourRange,
                        label: "h"
                    )
                    
                    // Minutes
                    pickerWheel(
                        value: $minutes,
                        range: minuteRange,
                        label: "m"
                    )
                    
                    // Seconds
                    pickerWheel(
                        value: $seconds,
                        range: secondRange,
                        label: "s"
                    )
                }
                .frame(height: 200)
                
                // Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        let totalSeconds = Double(hours * 3600 + minutes * 60 + seconds)
                        onSave(totalSeconds / 60) // Convert to minutes
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .systemBackground).opacity(0.8))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
            )
            .frame(maxWidth: 300)
        }
    }
    
    private func pickerWheel(
        value: Binding<Int>,
        range: ClosedRange<Int>,
        label: String
    ) -> some View {
        VStack(spacing: 8) {
            Picker("", selection: value) {
                ForEach(range, id: \.self) { number in
                    Text("\(number)")
                        .tag(number)
                        .foregroundColor(.primary)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 60)
            .clipped()
            .compositingGroup()
            .background(Color(uiColor: .systemBackground).opacity(0.01))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TimePickerView(
        isPresented: .constant(true),
        onSave: { _ in }
    )
} 