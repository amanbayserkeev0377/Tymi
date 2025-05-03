import SwiftUI

struct DayProgressCell: View {
    let date: Date
    let isSelected: Bool
    let progress: Double
    let isCurrentMonth: Bool
    let isDisabled: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    private let calendar = Calendar.current
    
    var body: some View {
        Group {
            if isDisabled {
                // Некликабельная ячейка для будущих дат
                ZStack {
                    // Фон ячейки (с эффектом отключения)
                    Circle()
                        .fill(isSelected ? Color.primary.opacity(0.1) : Color.clear)
                    
                    // Число
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                        .foregroundStyle(isCurrentMonth ? .tertiary : .quaternary)
                        .opacity(isCurrentMonth ? 0.7 : 0.3) // Снижаем непрозрачность для отключенных ячеек
                }
                .frame(height: 40)
            } else {
                // Кликабельная ячейка для прошлых/текущих дат
                Button(action: onSelect) {
                    ZStack {
                        // Фон ячейки
                        Circle()
                            .fill(isSelected ? Color.primary.opacity(0.2) : Color.clear)
                        
                        // Кольцо прогресса (если прогресс > 0)
                        if progress > 0 {
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    progressColor,
                                    style: StrokeStyle(
                                        lineWidth: 2.5,
                                        lineCap: .round
                                    )
                                )
                                .rotationEffect(.degrees(-90))
                        }
                        
                        // Число
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                            .foregroundStyle(isCurrentMonth ? .primary : .secondary)
                            .opacity(isCurrentMonth ? 1.0 : 0.5)
                    }
                    .frame(height: 40)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // Цвет прогресса в зависимости от значения
    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else {
            return .orange
        }
    }
}
