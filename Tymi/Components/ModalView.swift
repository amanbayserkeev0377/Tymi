import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    @GestureState private var dragOffset = CGSize.zero
    @State private var offset = CGSize.zero
    @State private var scrollOffset: CGFloat = 0
    
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
        GeometryReader { geometry in
            ZStack {
                // Modal content
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        Text(title)
                            .font(.title3.weight(.semibold))
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.medium))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    ScrollView {
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: proxy.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        content
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        scrollOffset = offset
                        
                        // Если скролл достиг верха и продолжаем тянуть вверх
                        if offset < -50 && dragOffset.height < 0 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: offset.height + dragOffset.height)
                .scaleEffect(
                    1.0 - ((offset.height + dragOffset.height) / (geometry.size.height * 4)),
                    anchor: .top
                )
                .opacity(
                    1.0 - ((offset.height + dragOffset.height) / (geometry.size.height * 2))
                )
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            // Разрешаем движение вниз всегда, а вверх только если достигли верха скролла
                            if value.translation.height > 0 || scrollOffset <= 0 {
                                state = value.translation
                            }
                        }
                        .onEnded { value in
                            let threshold = geometry.size.height * 0.15
                            if value.translation.height > threshold {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    offset = .zero
                                }
                            }
                        }
                )
            }
        }
        .transition(
            .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
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

extension View {
    func modalStyle(isPresented: Binding<Bool>, title: String) -> some View {
        ModalView(isPresented: isPresented, title: title) {
            self
        }
    }
} 
