import SwiftUI

struct ActiveDaysSectionContent: View {
    @Binding var activeDays: [Bool]
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = 0
    
    private var calendar: Calendar {
        return Calendar.userPreferred
    }

    private var daySymbols: [String] {
        return calendar.orderedWeekdayInitials
    }

    private var fullDayNames: [String] {
        return calendar.orderedWeekdaySymbols
    }
    
    private var activeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.7)
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
    
    private var buttonSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 52
        case .accessibility4: return 48
        case .accessibility3: return 46
        case .accessibility2: return 44
        case .accessibility1: return 42
        default: return 40
        }
    }
    
    private var fontSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 18
        case .accessibility4: return 17
        case .accessibility3: return 16.5
        case .accessibility2: return 16
        case .accessibility1: return 15.5
        default: return 15
        }
    }
    
    var body: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "cloud.sun")
                        .foregroundStyle(.primary)
                        .frame(width: 24, height: 24)
                    
                    Text("active_days".localized)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .frame(height: 37)
                
                Divider()
                    .padding(.leading, 24)
                
                HStack(spacing: 8) {
                    ForEach(0..<7) { index in
                        DayButton(
                            symbol: daySymbols[index],
                            fullName: fullDayNames[index],
                            isActive: activeDays[index],
                            size: buttonSize,
                            fontSize: fontSize,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            activeTextColor: activeTextColor,
                            inactiveTextColor: inactiveTextColor
                        ) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                activeDays[index].toggle()
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .onChange(of: firstDayOfWeek) { _, _ in
            Task { @MainActor in
                updateActiveDaysOrder()
            }
        }
    }
    
    private func updateActiveDaysOrder() {
        let calendar = Calendar.userPreferred
        var newActiveDays = Array(repeating: false, count: 7)
        
        for i in 0..<7 {
            if i < activeDays.count {
                let weekdayValue = calendar.systemWeekdayFromOrdered(index: i)
                let oldWeekday = Weekday(rawValue: weekdayValue) ?? .sunday
                let newIndex = Weekday.orderedByUserPreference.firstIndex(of: oldWeekday) ?? i
                
                if newIndex < 7 {
                    newActiveDays[newIndex] = activeDays[i]
                }
            }
        }
        
        activeDays = newActiveDays
    }
    
}



private struct DayButton: View {
    let symbol: String
    let fullName: String
    let isActive: Bool
    let size: CGFloat
    let fontSize: CGFloat
    let activeColor: Color
    let inactiveColor: Color
    let activeTextColor: Color
    let inactiveTextColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: fontSize))
                .frame(width: size, height: size)
                .background(isActive ? activeColor : inactiveColor)
                .foregroundStyle(isActive ? activeTextColor : inactiveTextColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fullName)
        .accessibilityValue(isActive ? "Selected" : "Not selected")
    }
}

#Preview {
    @Previewable @State var activeDays = [true, false, true, false, true, false, true]
    VStack {
        ActiveDaysSectionContent(activeDays: $activeDays)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .preferredColorScheme(.light)
        
        ActiveDaysSectionContent(activeDays: $activeDays)
            .padding()
            .background(Color.black)
            .cornerRadius(12)
            .preferredColorScheme(.dark)
    }
    .padding()
}
