import SwiftUI

struct ManualInputPanelView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let type: HabitType
    let onSubmit: (Double) -> Void
    
    // Default values for editing
    var initialValue: Double?
    
    // State for input fields
    @State private var countText: String = ""
    @State private var hoursText: String = ""
    @State private var minutesText: String = ""
    @State private var secondsText: String = ""
    
    // Focus state
    @FocusState private var focusedField: Field?
    
    enum Field {
        case count
        case hours
        case minutes
        case seconds
    }
    
    init(
        type: HabitType,
        isPresented: Binding<Bool>,
        initialValue: Double? = nil,
        onSubmit: @escaping (Double) -> Void
    ) {
        self.type = type
        self._isPresented = isPresented
        self.initialValue = initialValue
        self.onSubmit = onSubmit
        
        // Initialize state with initial value if provided
        if let value = initialValue {
            if type == .count {
                _countText = State(initialValue: "\(Int(value))")
            } else {
                let totalSeconds = Int(value * 60) // Convert minutes to seconds
                let hours = totalSeconds / 3600
                let minutes = (totalSeconds % 3600) / 60
                let seconds = totalSeconds % 60
                
                _hoursText = State(initialValue: "\(hours)")
                _minutesText = State(initialValue: "\(minutes)")
                _secondsText = State(initialValue: "\(seconds)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text(type == .count ? "Enter Count" : "Enter Time")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            
            // Input fields
            if type == .count {
                // Count input
                TextField("Count", text: $countText)
                    .keyboardType(.numberPad)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .count)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.primary.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .onAppear {
                        focusedField = .count
                    }
            } else {
                // Time input
                HStack(spacing: 16) {
                    // Hours
                    VStack(spacing: 4) {
                        TextField("0", text: $hoursText)
                            .keyboardType(.numberPad)
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .hours)
                            .onAppear {
                                focusedField = .hours
                            }
                        
                        Text("Hours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.primary.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    
                    // Minutes
                    VStack(spacing: 4) {
                        TextField("0", text: $minutesText)
                            .keyboardType(.numberPad)
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .minutes)
                        
                        Text("Minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.primary.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    
                    // Seconds
                    VStack(spacing: 4) {
                        TextField("0", text: $secondsText)
                            .keyboardType(.numberPad)
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .seconds)
                        
                        Text("Seconds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                Color.primary.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                }
            }
            
            // Buttons
            HStack(spacing: 16) {
                //Cancel
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.08)
                                    : Color.black.opacity(0.05)
                                )
                        )
                }
                
                // Done
                Button {
                    submitValue()
                } label: {
                    Text("Done")
                        .font(.body.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? .black.opacity(0.6) : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.4)
                                    : Color.black
                                )
                        )
                }
            }
        }
        .padding(24)
        .glassCard()
        .frame(maxWidth: 400)
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func submitValue() {
        if type == .count {
            if let value = Double(countText) {
                onSubmit(value)
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
        } else {
            // Convert hours, minutes, seconds to total minutes
            let hours = Double(hoursText) ?? 0
            let minutes = Double(minutesText) ?? 0
            let seconds = Double(secondsText) ?? 0
            
            let totalSeconds = hours * 3600 + minutes * 60 + seconds
            let totalMinutes = totalSeconds / 60
            
            onSubmit(totalMinutes)
            withAnimation(.easeInOut(duration: 0.3)) {
                isPresented = false
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            ManualInputPanelView(
                type: .time,
                isPresented: .constant(true),
                initialValue: 30,
                onSubmit: { _ in }
            )
        }
    }
    .preferredColorScheme(.dark)
} 
