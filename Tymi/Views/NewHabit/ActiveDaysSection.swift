import SwiftUI

struct ActiveDaysSection: View {
    @Binding var activeDays: [Bool]
    @Environment(\.colorScheme) private var colorScheme
    
    // Calendar for day names
    private let calendar = Calendar.current
    
    // Day symbols (short names like "Mon", "Tue")
    private var daySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols // e.g., ["Mon", "Tue", ...]
        
        // Rearrange symbols based on first day of week
        let firstWeekday = calendar.firstWeekday - 1
        let before = Array(symbols[firstWeekday...])
        let after = Array(symbols[..<firstWeekday])
        return before + after
    }
    
    // Full day names for accessibility
    private var fullDayNames: [String] {
        let names = calendar.weekdaySymbols
        
        // Rearrange names based on first day of week
        let firstWeekday = calendar.firstWeekday - 1
        let before = Array(names[firstWeekday...])
        let after = Array(names[..<firstWeekday])
        return before + after
    }
    
    private var activeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : .black
    }
    
    private var inactiveColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    private var activeTextColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var inactiveTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private let minTapSize: CGFloat = 44
    
    var body: some View {
        Section {
            // Days Grid
            HStack(spacing: 8) { // Consistent spacing between buttons
                ForEach(0..<7) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            activeDays[index].toggle()
                        }
                    } label: {
                        Text(daySymbols[index]) // Use full short names like "Mon"
                            .font(.body)
                            .frame(width: 44, height: 44)
                            .background(activeDays[index] ? activeColor : inactiveColor)
                            .foregroundStyle(activeDays[index] ? activeTextColor : inactiveTextColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain) // Prevents default button styling
                    .accessibilityLabel("\(fullDayNames[index])")
                    .accessibilityValue(activeDays[index] ? "Active" : "Inactive")
                    .accessibilityHint("Double tap to toggle \(fullDayNames[index])")
                }
            }
            .padding(.horizontal)
        } header: {
            Text("Active Days")
        }
    }
}

#Preview {
    @Previewable @State var activeDays = [true, false, true, false, true, false, true]
        Form {
            ActiveDaysSection(activeDays: $activeDays)
        }
}
