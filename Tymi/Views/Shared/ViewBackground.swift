import SwiftUI

struct ViewBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Базовый цвет
            Color(colorScheme == .dark ? .black : Color(red: 242/255, green: 241/255, blue: 246/255)) // Более приглушенный, с легким серым оттенком
            
            // Мягкий градиент
            LinearGradient(
                colors: colorScheme == .dark
                ? [
                    Color(red: 28/255, green: 28/255, blue: 30/255).opacity(0.95),
                    Color(red: 35/255, green: 35/255, blue: 37/255).opacity(0.85),
                    Color(red: 40/255, green: 40/255, blue: 42/255).opacity(0.8)
                ]
                : [
                    Color(red: 240/255, green: 238/255, blue: 244/255).opacity(0.7), // Верхний слой, более серый
                    Color(red: 242/255, green: 240/255, blue: 246/255).opacity(0.5), // Средний слой
                    Color(red: 244/255, green: 242/255, blue: 248/255).opacity(0.3)  // Нижний слой
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Дополнительный градиент для теплого оттенка
            LinearGradient(
                colors: colorScheme == .dark
                ? []
                : [
                    Color(red: 252/255, green: 242/255, blue: 248/255).opacity(0.15), // Очень нежный розовый
                    Color(red: 246/255, green: 242/255, blue: 250/255).opacity(0.1)   // Очень нежный фиолетовый
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Тонкая текстура шума
            NoisePattern()
                .opacity(colorScheme == .dark ? 0.05 : 0.012) // Минимальный шум в светлой теме
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
}

// Шум для создания текстуры
private struct NoisePattern: View {
    var body: some View {
        Canvas { context, size in
            // Создаем шахматный узор
            let cellSize: CGFloat = 1 // Размер ячейки оставляем маленьким для тонкой текстуры
            let rows = Int(size.height / cellSize)
            let cols = Int(size.width / cellSize)
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let opacity = Double.random(in: 0...0.01) // Минимальная прозрачность для более тонкого эффекта
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    
                    context.opacity = opacity
                    context.fill(Path(rect), with: .color(.white))
                }
            }
        }
    }
}

// ViewBackgroundModifier для легкого применения фона
struct ViewBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            ViewBackground()
            content
        }
    }
}

// Extension для удобного использования
extension View {
    func withBackground() -> some View {
        modifier(ViewBackgroundModifier())
    }
}

#Preview {
    VStack {
        Text("Светлый режим")
            .font(.title)
            .padding()
    }
    .withBackground()
    .preferredColorScheme(.light)
}

#Preview {
    VStack {
        Text("Темный режим")
            .font(.title)
            .padding()
    }
    .withBackground()
    .preferredColorScheme(.dark)
}
