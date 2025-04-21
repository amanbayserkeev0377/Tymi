import SwiftUI

struct WheelPickerView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isPresented: Bool
    let onSubmit: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                hoursWheel
                separatorText
                minutesWheel
            }
            
            doneButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Subviews
    
    private var hoursWheel: some View {
        Picker("", selection: $hours) {
            ForEach(0...23, id: \.self) { hour in
                Text("\(hour)").tag(hour)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 64)
        .clipped()
        .labelsHidden()
    }
    
    private var separatorText: some View {
        Text(":")
            .font(.title3)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }
    
    private var minutesWheel: some View {
        Picker("", selection: $minutes) {
            ForEach(0...59, id: \.self) { minute in
                Text(String(format: "%02d", minute)).tag(minute)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 64)
        .clipped()
        .labelsHidden()
    }
    
    private var doneButton: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .tint(.red)
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.1))
            )
            
            Spacer()
            
            Button("Done") {
                submitValue()
                isPresented = false
            }
            .tint(.primary)
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.1))
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func submitValue() {
        let totalSeconds = hours * 3600 + minutes * 60
        onSubmit(totalSeconds)
    }
}
