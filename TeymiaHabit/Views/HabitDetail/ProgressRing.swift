import SwiftUI

struct ProgressRing: View {
    // MARK: - Properties
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    
    // Размеры и стили
    var size: CGFloat = 180
    var lineWidth: CGFloat? = nil
    var fontSize: CGFloat? = nil
    var iconSize: CGFloat? = nil
    
    // MARK: - Computed Properties
    
    // Упрощаем цветовую схему - один и тот же цвет для выполнения/перевыполнения
    private var ringColors: [Color] {
        if isCompleted || isExceeded {
            return [
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1)),
                Color(#colorLiteral(red: 0.1803921569, green: 0.5450980392, blue: 0.3411764706, alpha: 1)),
                Color(#colorLiteral(red: 0.8196078431, green: 1, blue: 0.8352941176, alpha: 1)),
                Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
            ]
        } else {
            return [
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)),
                Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.8805306554, blue: 0.5692787766, alpha: 1)),
                Color(#colorLiteral(red: 1, green: 0.6470588235, blue: 0, alpha: 1)),
                Color(#colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
            ]
        }
    }
    
    private var textColor: Color {
        if isCompleted || isExceeded {
            return Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
        } else {
            return .primary
        }
    }
    
    // Адаптивная толщина линии кольца с фиксированным соотношением
    private var adaptiveLineWidth: CGFloat {
        return lineWidth ?? (size * 0.11)
    }
    
    // Адаптивный размер шрифта для текста значения
    private var adaptedFontSize: CGFloat {
        if let customFontSize = fontSize {
            return customFontSize
        }
        
        let baseSize = size * 0.25
        
        let digitsCount = currentValue.filter { $0.isNumber }.count
        
        let factor: CGFloat
        switch digitsCount {
        case 0...3: // 1, 12, 123, 999
            factor = 1.0
        case 4: // 1000, 1 000, 9999
            factor = 0.9
        case 5: // 10000, 10 000, 99999
            factor = 0.85
        case 6: // 100000, 100 000, 999999
            factor = 0.75
        default: // Более длинные строки
            factor = 0.65
        }
        
        return baseSize * factor
    }
    
    // Адаптивный размер иконки галочки
    private var adaptedIconSize: CGFloat {
        return iconSize ?? (size * 0.4)
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: adaptiveLineWidth)
            
            // Кольцо прогресса с анимацией
            ProgressRingCircle(
                progress: progress,
                ringColors: ringColors,
                lineWidth: adaptiveLineWidth
            )
            .animation(.easeInOut(duration: 0.3), value: progress)
            
            // Текст в центре или галочка для выполненных привычек БЕЗ анимации
            if isCompleted && !isExceeded {
                Image(systemName: "checkmark")
                    .font(.system(size: adaptedIconSize, weight: .bold))
                    .foregroundStyle(textColor)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            } else {
                Text(currentValue)
                    .font(.system(size: adaptedFontSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        if isCompleted {
            return "habit_completed".localized
        } else if isExceeded {
            return "habit_exceeded".localized
        } else {
            return "habit_progress".localized
        }
    }
    
    private var accessibilityValue: String {
        if isCompleted {
            return "completion_100_percent".localized
        } else if isExceeded {
            return "completion_exceeded".localized(with: Int(progress * 100))
        } else {
            return "completion_percent".localized(with: Int(progress * 100))
        }
    }
}

// Выделяем круг прогресса в отдельную структуру для более ясного контроля анимации
struct ProgressRingCircle: View {
    let progress: Double
    let ringColors: [Color]
    let lineWidth: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: min(progress, 1.0)) // Ограничиваем до 100%
            .stroke(
                AngularGradient(
                    colors: ringColors,
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
    }
}
