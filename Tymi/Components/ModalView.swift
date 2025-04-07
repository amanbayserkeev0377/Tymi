import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    
    private let dismissThreshold: CGFloat = 100
    
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
                
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: offset)
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.3), value: offset)
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom),
                removal: .move(edge: .bottom).combined(with: .opacity)
            )
        )
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { gesture in
                    isDragging = true
                    let translation = gesture.translation.height
                    
                    // Замедляем движение вверх
                    if translation < 0 {
                        offset = translation / 3
                    } else {
                        offset = translation
                    }
                }
                .onEnded { gesture in
                    isDragging = false
                    let translation = gesture.translation.height
                    let velocity = gesture.predictedEndLocation.y - gesture.location.y
                    
                    if translation > dismissThreshold || (translation > 20 && velocity > 500) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
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
