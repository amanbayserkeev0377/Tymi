import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    // Вычисляем прозрачность на основе смещения
    private var opacity: CGFloat {
        let maxOffset: CGFloat = 200 // Максимальное смещение для полного исчезновения
        return 1 - (offset / maxOffset)
    }
    
    init(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    // Ручка
                    Capsule()
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.3 : 0.15))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                    
                    // Header
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .padding(.vertical, 8)
                    
                    // Геометрия для отслеживания скролла
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    content
                        .padding(.bottom, 32) // Отступ снизу
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        // Если скролл в самом верху, разрешаем тянуть вниз
                        if scrollOffset >= 0 {
                            let translation = value.translation.height
                            offset = translation > 0 ? translation : 0
                        }
                    }
                    .onEnded { value in
                        if scrollOffset >= 0 {
                            let translation = value.translation.height
                            if translation > 50 {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isPresented = false
                                }
                            } else {
                                withAnimation(.interactiveSpring(
                                    response: 0.3,
                                    dampingFraction: 0.7,
                                    blendDuration: 0
                                )) {
                                    offset = 0
                                }
                            }
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: offset)
        .opacity(opacity)
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        )
    }
    
    func dismiss() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func modalStyle(isPresented: Binding<Bool>, title: String) -> some View {
        ModalView(isPresented: isPresented, title: title) {
            self
        }
    }
} 
