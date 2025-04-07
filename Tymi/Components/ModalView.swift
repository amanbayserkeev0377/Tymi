import SwiftUI

struct ModalView<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    @State private var offset: CGFloat = 0
    
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
            // Modal content
            VStack(spacing: 0) {
                // Header
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
                
                ScrollView {
                    content
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: offset)
            
            // Overlay для жестов
            Color.black.opacity(0.01) // Почти прозрачный для жестов
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            offset = translation > 0 ? translation : 0
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            if translation > 50 {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offset = 1000
                                    isPresented = false
                                }
                            } else {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offset = 0
                                }
                            }
                        }
                )
        }
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

extension View {
    func modalStyle(isPresented: Binding<Bool>, title: String) -> some View {
        ModalView(isPresented: isPresented, title: title) {
            self
        }
    }
} 
