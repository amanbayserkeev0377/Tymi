import SwiftUI

struct ManualInputPanelView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let type: HabitType
    let onSubmit: (Double) -> Void
    let isAddMode: Bool // true - добавить значение, false - изменить значение
    
    // Default values for editing
    var initialValue: Double?
    
    // State for input fields
    @State private var countText: String = ""
    @State private var hoursText: String = "0"
    @State private var minutesText: String = "0"
    @State private var secondsText: String = "0"
    
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
        isAddMode: Bool = false,
        onSubmit: @escaping (Double) -> Void
    ) {
        self.type = type
        self._isPresented = isPresented
        self.initialValue = initialValue
        self.isAddMode = isAddMode
        self.onSubmit = onSubmit
        
        // Initialize state with initial value if provided
        if let value = initialValue {
            if type == .count {
                _countText = State(initialValue: "\(Int(value))")
            } else {
                let totalSeconds = Int(value)
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
            Text(type == .count ? (isAddMode ? "Add Count" : "Change Count") : (isAddMode ? "Add Time" : "Change Time"))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            
            if type == .count {
                TextField("", text: $countText)
                    .keyboardType(.numberPad)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .count)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .onAppear {
                        focusedField = .count
                    }
            } else {
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        TextField("0", text: $hoursText)
                            .keyboardType(.numberPad)
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .hours)
                            .foregroundStyle(hoursText == "0" && focusedField != .hours ? .secondary : .primary)
                            .onChange(of: focusedField) { oldValue, newValue in
                                if newValue == .hours && hoursText == "0" {
                                    hoursText = ""
                                }
                            }
                        
                        Text("Hours")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .onAppear {
                        focusedField = .hours
                    }
                    
                    VStack(spacing: 4) {
                        TextField("0", text: $minutesText)
                            .keyboardType(.numberPad)
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .minutes)
                            .foregroundStyle(minutesText == "0" && focusedField != .minutes ? .secondary : .primary)
                            .onChange(of: focusedField) { oldValue, newValue in
                                if newValue == .minutes && minutesText == "0" {
                                    minutesText = ""
                                }
                            }
                        
                        Text("Minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    
                    VStack(spacing: 4) {
                        TextField("0", text: $secondsText)
                            .keyboardType(.numberPad)
                            .font(.title2.weight(.medium))
                            .multilineTextAlignment(.center)
                            .focused($focusedField, equals: .seconds)
                            .foregroundStyle(secondsText == "0" && focusedField != .seconds ? .secondary : .primary)
                            .onChange(of: focusedField) { oldValue, newValue in
                                if newValue == .seconds && secondsText == "0" {
                                    secondsText = ""
                                }
                            }
                        
                        Text("Seconds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            HStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Text("Cancel")
                        .font(.body.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? .white.opacity(0.6) : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.08)
                                    : Color.black.opacity(0.05)
                                )
                                .stroke(
                                    colorScheme == .dark
                                    ? Color.white.opacity(0.2)
                                    : Color.black.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                }
                
                Button {
                    if type == .count {
                        if let value = Double(countText) {
                            onSubmit(value)
                        }
                    } else {
                        let hours = Double(hoursText.isEmpty ? "0" : hoursText) ?? 0
                        let minutes = Double(minutesText.isEmpty ? "0" : minutesText) ?? 0
                        let seconds = Double(secondsText.isEmpty ? "0" : secondsText) ?? 0
                        let totalSeconds = hours * 3600 + minutes * 60 + seconds
                        onSubmit(totalSeconds)
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Text(isAddMode ? "Add" : "Save")
                        .font(.body.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
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
            .padding(.top, 8)
        }
        .padding(24)
        .glassCard()
        .frame(maxWidth: 400)
        .padding(.horizontal, 24)
        .onChange(of: focusedField) { oldValue, newValue in
            if newValue == nil {
                let hoursValue = Double(hoursText) ?? 0
                let minutesValue = Double(minutesText) ?? 0
                let totalValue = hoursValue * 3600 + minutesValue * 60
                onSubmit(totalValue)
                isPresented = false
            }
        }
    }
}
