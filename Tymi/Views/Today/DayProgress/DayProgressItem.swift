import SwiftUI

struct DayProgressItem: View {
    let date: Date
    let isSelected: Bool
    let progress: Double
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = 0
    
    private var calendar: Calendar {
        return Calendar.userPreferred
    }
    
    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isFutureDate: Bool {
        date > Date()
    }
    
    private var isValidDate: Bool {
        date <= Date().addingTimeInterval(86400 * 365) // Не более года в будущем
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
    
    private var circleSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5:
            return 44
        case .accessibility4:
            return 40
        case .accessibility3:
            return 38
        case .accessibility2:
            return 36
        case .accessibility1:
            return 34
        default:
            return 32
        }
    }
    
    private var fontSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5:
            return 17
        case .accessibility4:
            return 16
        case .accessibility3:
            return 15.5
        case .accessibility2:
            return 15
        case .accessibility1:
            return 14.5
        default:
            return 14
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    if isFutureDate {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: circleSize, height: circleSize)
                    } else {
                        Circle()
                            .stroke(Color.secondary.opacity(0.1), lineWidth: 4)
                            .frame(width: circleSize, height: circleSize)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(
                                    colors: progressColors,
                                    center: .center,
                                    startAngle: .degrees(0),
                                    endAngle: .degrees(360)
                                ),
                                style: StrokeStyle(
                                    lineWidth: 4,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: circleSize, height: circleSize)
                    }
                    
                    if isFutureDate {
                        Text(dayNumber)
                            .font(.system(size: fontSize, weight: .regular))
                            .foregroundStyle(.tertiary)
                    } else if isToday {
                        Text(dayNumber)
                            .font(.system(size: fontSize, weight: .bold))
                            .foregroundColor(Color.orange)
                    } else {
                        Text(dayNumber)
                            .font(.system(size: fontSize, weight: isSelected ? .bold : .regular))
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
            .frame(width: circleSize + 8, height: circleSize + 24)
            .opacity(isFutureDate ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFutureDate || !isValidDate)
    }
}
