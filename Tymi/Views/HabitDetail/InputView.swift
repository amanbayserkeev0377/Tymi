import SwiftUI

// MARK: - TimeUnit
enum TimeUnit: String, CaseIterable {
    case sec, min, hr
}

// MARK: - InputOverlay
struct InputOverlay: View {
    let habitType: HabitType
    @Binding var isInputFocused: Bool
    @Binding var inputValue: String
    let onSubmit: (Int) -> Void
    
    var body: some View {
        ZStack {
            
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }
            
            VStack {
                Spacer()
                
                
                VStack(spacing: 0) {
                    if habitType == .count {
                        CountInputView(value: $inputValue) { value in
                            onSubmit(value)
                            isInputFocused = false
                        }
                    } else {
                        TimeInputView(value: $inputValue) { seconds in
                            onSubmit(seconds)
                            isInputFocused = false
                        }
                    }
                }
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(16, corners: [.topLeft, .topRight])
            }
            .transition(.move(edge: .bottom))
        }
    }
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                              cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - TimeInputView
struct TimeInputView: View {
    @Binding var value: String
    @State private var selectedUnit: TimeUnit = .min
    @FocusState private var isFocused: Bool
    let onSubmit: (Int) -> Void
    
    private func convertToSeconds() -> Int? {
        guard let value = Int(value) else { return nil }
        switch selectedUnit {
            case .sec: return value
            case .min: return value * 60
            case .hr: return value * 3600
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Value", text: $value)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .frame(maxWidth: .infinity)
                
                Button(action: {
                    if let seconds = convertToSeconds() {
                        onSubmit(seconds)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 20, weight: .semibold))
                }
            }
            
            HStack {
                ForEach(TimeUnit.allCases, id: \.self) { unit in
                    Button(action: {
                        selectedUnit = unit
                    }) {
                        Text(unit.rawValue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedUnit == unit ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                            .foregroundColor(selectedUnit == unit ? .blue : .gray)
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - CountInputView
struct CountInputView: View {
    @Binding var value: String
    @FocusState private var isFocused: Bool
    let onSubmit: (Int) -> Void
    
    var body: some View {
        HStack {
            TextField("Value", text: $value)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .frame(maxWidth: .infinity)
            
            Button(action: {
                if let intValue = Int(value) {
                    onSubmit(intValue)
                }
            }) {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.system(size: 20, weight: .semibold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .onAppear {
            isFocused = true
        }
    }
}
