import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let showCloseButton: Bool
    let content: Content
    
    @GestureState private var dragOffset = CGSize.zero
    @State private var offset = CGSize.zero
    
    init(
        isPresented: Binding<Bool>,
        showCloseButton: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.showCloseButton = showCloseButton
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modal content
                VStack {
                    if showCloseButton {
                        HStack {
                            Spacer()
                            
                            Button {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(GlassButtonStyle(size: 44))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                    
                    content
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
                            if value.translation.height > 0 {
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
}

extension View {
    func modalStyle(isPresented: Binding<Bool>, showCloseButton: Bool = true) -> some View {
        ModalView(isPresented: isPresented, showCloseButton: showCloseButton) {
            self
        }
    }
} 
