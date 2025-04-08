import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    @State private var offset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging = false
    @GestureState private var dragState = DragState.inactive
    
    private let dismissThreshold: CGFloat = 100
    
    enum DragState {
        case inactive
        case dragging(translation: CGFloat)
        
        var translation: CGFloat {
            switch self {
            case .inactive:
                return 0
            case .dragging(let translation):
                return translation
            }
        }
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
            // Background overlay
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
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
                
                ScrollView {
                    content
                        .padding(.bottom, 32) // Добавляем отступ снизу для контента
                }
                .simultaneousGesture(
                    DragGesture()
                        .updating($dragState) { value, state, _ in
                            // Обновляем состояние драга только если скролл в начале
                            if scrollOffset <= 0 {
                                state = .dragging(translation: value.translation.height)
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            let velocity = value.predictedEndLocation.y - value.location.y
                            
                            if (translation > dismissThreshold || (translation > 20 && velocity > 500)) && scrollOffset <= 0 {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isPresented = false
                                }
                            }
                        }
                )
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                    }
                )
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: dragState.translation)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.3), value: dragState.translation)
            .transition(
                .asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                )
            )
        }
        .coordinateSpace(name: "scroll")
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
