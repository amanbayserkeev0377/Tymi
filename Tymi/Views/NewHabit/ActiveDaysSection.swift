import SwiftUI

struct ActiveDaysSection: View {
    @Binding var activeDays: [Bool]
    @Environment(\.colorScheme) private var colorScheme
    
    // Calendar for day names
    private let calendar = Calendar.current
    
    // Day symbols
    private var daySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        
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
        colorScheme == .dark ? .white : .black
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
    
    // Minimum tap size (44x44 for accessibility)
    private let minTapSize: CGFloat = 44
    
    var body: some View {
        Section {
            // Using GeometryReader to make sure we adapt to different screen sizes
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let itemSize = min(max(30, availableWidth / 10), 40) // Smaller sizes for small screens
                
                // Day selection circles in compact layout
                HStack(spacing: 0) {
                    ForEach(0..<7) { index in
                        ZStack {
                            Circle()
                                .fill(activeDays[index] ? activeColor : inactiveColor)
                                .frame(width: itemSize, height: itemSize)
                            
                            Text(daySymbols[index].prefix(1))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(activeDays[index] ? activeTextColor : inactiveTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: minTapSize) // Ensure minimum tap area
                        .contentShape(Rectangle()) // Make entire area tappable
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeDays[index].toggle()
                            }
                        }
                        .accessibilityLabel("\(fullDayNames[index])")
                        .accessibilityValue(activeDays[index] ? "Active" : "Inactive")
                        .accessibilityHint("Double tap to toggle \(fullDayNames[index])")
                    }
                }
                .frame(height: max(itemSize, minTapSize))
            }
            .frame(height: 44)
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
