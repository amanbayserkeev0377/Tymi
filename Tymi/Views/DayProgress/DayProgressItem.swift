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
    
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress > 0 {
            return .orange
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // День недели (Пн, Вт, ...)
                Text(dayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                // Кружок с числом и индикатором прогресса
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              (colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)) :
                              Color.clear)
                        .frame(width: 40, height: 40)
                    
                    // Индикатор прогресса
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(
                                lineWidth: 2,
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
                .overlay(
                    Circle()
                        .stroke(isToday ? .primary : Color.clear, lineWidth: isToday ? 1 : 0)
                        .frame(width: 40, height: 40)
                )
            }
            .frame(width: 44, height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
