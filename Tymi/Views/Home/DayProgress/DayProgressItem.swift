import SwiftUI

struct DayProgressItem: View, Equatable {
    let date: Date
    let isSelected: Bool
    let progress: Double
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
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
        date <= Date().addingTimeInterval(86400 * 365)
    }
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
        } else if progress > 0 {
            return Color(#colorLiteral(red: 1, green: 0.3806057187, blue: 0.1013509959, alpha: 1))
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    // Размеры для разных значений dynamic type
    private var circleSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 40
        case .accessibility4: return 38
        case .accessibility3: return 36
        case .accessibility2: return 34
        case .accessibility1: return 32
        default: return 30
        }
    }
    
    private var lineWidth: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5, .accessibility4, .accessibility3:
            return 4.0
        case .accessibility2, .accessibility1:
            return 3.8
        default:
            return 3.5  // Увеличиваем с 2.5 до 3.5 для более заметных кругов
        }
    }
    
    private var fontSize: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 17
        case .accessibility4: return 16
        case .accessibility3: return 15
        case .accessibility2: return 14
        case .accessibility1: return 13.5
        default: return 13
        }
    }
    
    // Цвет текста для дня
    private var dayTextColor: Color {
        if isToday {
            return .orange // Сегодняшний день всегда оранжевый
        } else if isSelected {
            return .primary // Выбранный день primary
        } else if isFutureDate {
            return .secondary.opacity(0.6) // Будущие дни серые и прозрачные
        } else {
            return .secondary // Остальные дни серые
        }
    }
    
    // Вес шрифта
    private var fontWeight: Font.Weight {
        if isSelected {
            return .bold // Выбранный день bold
        } else {
            return .regular // Остальные regular
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Круг прогресса и число
                ZStack {
                    if !isFutureDate {
                        Circle()
                            .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                progressColor,
                                style: StrokeStyle(
                                    lineWidth: lineWidth,
                                    lineCap: .round
                                )
                            )
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // Число дня месяца
                    Text(dayNumber)
                        .font(.system(size: fontSize, weight: fontWeight))
                        .foregroundColor(dayTextColor)
                }
                .frame(width: circleSize, height: circleSize)
                
                // Индикатор выбранного дня (точка под числом)
                Circle()
                    .fill(isToday ? Color.orange : Color.primary) // Цвет точки
                    .frame(width: 4, height: 4)
                    .opacity(isSelected ? 1 : 0) // Показывать только для выбранного дня
            }
            .opacity(isFutureDate ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isFutureDate || !isValidDate)
    }
    
    // Реализация Equatable для оптимизации перерисовки
    static func == (lhs: DayProgressItem, rhs: DayProgressItem) -> Bool {
        return Calendar.current.isDate(lhs.date, inSameDayAs: rhs.date) &&
               lhs.isSelected == rhs.isSelected &&
               abs(lhs.progress - rhs.progress) < 0.01
    }
}
