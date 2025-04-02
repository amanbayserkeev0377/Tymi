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
        ZStack {
            // Dimmed background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Modal content
            VStack {
                if showCloseButton {
                    HStack {
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
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
            .offset(y: offset.height + dragOffset.height)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        if value.translation.height > 0 {
                            state = value.translation
                        }
                    }
                    .onEnded { value in
                        let threshold = UIScreen.main.bounds.height * 0.15
                        if value.translation.height > threshold {
                            withAnimation(.spring(response: 0.3)) {
                                isPresented = false
                            }
                        } else {
                            withAnimation(.spring(response: 0.3)) {
                                offset = .zero
                            }
                        }
                    }
            )
        }
    }
}

extension View {
    func modalStyle(isPresented: Binding<Bool>, showCloseButton: Bool = true) -> some View {
        ModalView(isPresented: isPresented, showCloseButton: showCloseButton) {
            self
        }
    }
} 