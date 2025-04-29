import SwiftUI

struct ActiveDaysSectionContent: View {
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
    
    var body: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "cloud.sun")
                        .foregroundStyle(.primary)
                        .frame(width: 24, height: 24)
                    
                    Text("Active Days")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                }
                .frame(height: 37)
                
                Divider()
                .padding(.leading, 24)
                
                // Days Grid
                HStack(spacing: 8) {
                    ForEach(0..<7) { index in
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                activeDays[index].toggle()
                            }
                        } label: {
                            Text(daySymbols[index])
                                .font(.body)
                                .frame(width: 44, height: 44)
                                .background(activeDays[index] ? activeColor : inactiveColor)
                                .foregroundStyle(activeDays[index] ? activeTextColor : inactiveTextColor)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)
            }
        }
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
