import SwiftUI

struct DayProgressItem: View {
    let date: Date
    let isSelected: Bool
    let progress: Double
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        "\(calendar.component(.day, from: date))"
    }
    
    private var dayName: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    // Градиентные цвета для прогресса, как в других компонентах
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
            VStack(spacing: 8) {
                // День недели (Пн, Вт, ...)
                Text(dayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                // Кружок с числом и индикатором прогресса
                ZStack {
                    // Фоновый круг для индикатора прогресса
                    Circle()
                        .stroke(Color.secondary.opacity(0.1), lineWidth: 4)
                        .frame(width: 36, height: 36)
                    
                    // Индикатор прогресса
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
                        .frame(width: 36, height: 36)
                    
                    // Число
                    Text(dayNumber)
                        .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                }
                
                // Индикатор выбранного дня (точка снизу)
                if isSelected {
                    Circle()
                        .fill(.primary)
                        .frame(width: 5, height: 5)
                        .padding(.top, -2)
                }
            }
            .frame(width: 44, height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
