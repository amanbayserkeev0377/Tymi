import SwiftUI
import UIKit

struct ProgressRing: View {
    let progress: Double
    let currentValue: String
    let isCompleted: Bool
    let isExceeded: Bool
    var size: CGFloat = 180
    var lineWidth: CGFloat = 22
    var fontSize: CGFloat = 36
    var iconSize: CGFloat = 64
    @Environment(\.colorScheme) var colorScheme
    
    private var ringColors: [Color] {
        if isExceeded {
            return [
                Color(#colorLiteral(red: 0.2588235294, green: 0.3921568627, blue: 1, alpha: 1)),
                Color(#colorLiteral(red: 0.9222695707, green: 0.1548486791, blue: 0.2049736653, alpha: 1)),
                Color(#colorLiteral(red: 0.2588235294, green: 0.3921568627, blue: 1, alpha: 1))
            ]
        } else if isCompleted {
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
        if isExceeded {
            return Color(#colorLiteral(red: 1, green: 0.3806057187, blue: 0.1013509959, alpha: 1))
        } else if isCompleted {
            return Color(#colorLiteral(red: 0.2980392157, green: 0.7333333333, blue: 0.09019607843, alpha: 1))
        } else {
            return .primary
        }
    }
    
    private var rotationAngle: Double {
        if isExceeded {
            return (progress - 1.0) * 360
        }
        return 0
    }
    
    private var adjustedFontSize: CGFloat {
        // Если значение содержит двоеточие (время) и длиннее 5 символов
        if currentValue.contains(":") && currentValue.count > 5 {
            return fontSize - 2
        }
        // Для маленьких чисел (до 9999) используем больший размер
        if let number = Int(currentValue), number < 10000 {
            return fontSize + 8
        }
        return fontSize
    }
    
    var body: some View {
        ZStack {
            // Фоновый круг
            Circle()
                .stroke(Color.secondary.opacity(0.1), lineWidth: lineWidth)
            
            // Кольцо прогресса
            Circle()
                .trim(from: 0, to: isExceeded ? 1 : progress)
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
                .rotationEffect(.degrees(rotationAngle))
            
            // Текст в центре
            if isCompleted && !isExceeded {
                Image(systemName: "checkmark")
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(textColor)
            } else {
                Text(currentValue)
                    .font(.system(size: adjustedFontSize, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.3), value: progress)
    }
}
