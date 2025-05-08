import SwiftUI

struct DayProgressItem: View {
    let date: Date
    let isSelected: Bool
    let progress: Double
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var calendarManager = CalendarManager.shared
    
    private var dayNumber: String {
        "\(calendarManager.calendar.component(.day, from: date))"
    }
    
    private var isToday: Bool {
        calendarManager.calendar.isDateInToday(date)
    }
    
    private var isFutureDate: Bool {
        date > Date()
    }
    
    private var progressColors: [Color] {
        if progress >= 1.0 {
            return [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ]
        } else if progress > 0 {
            return [
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8805306554, blue: 0.5692787766, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.6470588235, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
            ]
        } else {
            return [Color.gray.opacity(0.3)]
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: progressColors,
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    if isFutureDate {
                        Text(dayNumber)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.tertiary)
                    } else if isToday {
                        Text(dayNumber)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.orange)
                    } else {
                        Text(dayNumber)
                            .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                }
                
                if isSelected && !isFutureDate {
                    Circle()
                        .fill(isToday ? Color.orange : Color.primary)
                        .frame(width: 5, height: 5)
                } else {
                    Color.clear
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 44, height: 60)
            .opacity(isFutureDate ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFutureDate)
    }
}
