import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    @State private var offset: CGFloat = 0
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
        ZStack(alignment: .top) {
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Геометрия для отслеживания скролла
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    content
                        .padding(.top, 44) // Высота header
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
                            withAnimation(.interactiveSpring()) {
                                offset = translation > 0 ? translation : 0
                            }
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
                                withAnimation(.interactiveSpring()) {
                                    offset = 0
                                }
                            }
                        }
                    }
            )
            
            // Fixed Header
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text(title)
                        .font(.title3.weight(.semibold))
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Spacer()
            }
            .frame(height: 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: offset)
        .transition(.move(edge: .bottom))
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
