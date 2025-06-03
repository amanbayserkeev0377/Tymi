import SwiftUI

struct EmptyStateView: View {
    @State private var isAnimating = false
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 30
    @State private var hintOpacity: Double = 0
    @State private var hintOffset: CGFloat = 30
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        VStack(spacing: 40) {
            Image("TeymiaHabitBlank")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .scaleEffect(isAnimating ? 1.15 : 0.9)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            VStack(spacing: 16) {
                Text("empty_view_largetitle".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)
                    .offset(y: titleOffset)
                
                Text("empty_view_title3".localized)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .lineLimit(nil)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
            
            // Подсказка о FAB
            HStack(spacing: 8) {
                Text("empty_view_tap".localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Image(systemName: "plus")
                    .font(.footnote)
                    .foregroundStyle(colorManager.selectedColor.color)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(colorManager.selectedColor.color.opacity(0.1))
                    )
                
                Text("empty_view_to_create_habit".localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            .opacity(hintOpacity)
            .offset(y: hintOffset)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .onAppear {
            // Поэтапное появление с красивыми задержками
            
            // 1. Заголовок появляется первым
            withAnimation(.easeOut(duration: 1.5).delay(0.8)) {
                titleOpacity = 1.0
                titleOffset = 0
            }
            
            // 2. Подзаголовок появляется вторым
            withAnimation(.easeOut(duration: 1.5).delay(1.6)) {
                subtitleOpacity = 1.0
                subtitleOffset = 0
            }
            
            // 3. Подсказка появляется последней
            withAnimation(.easeOut(duration: 1.2).delay(2.4)) {
                hintOpacity = 1.0
                hintOffset = 0
            }
        }
    }
}
