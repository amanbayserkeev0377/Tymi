import SwiftUI

struct BottomSheetView<Content: View>: View {
    let content: Content
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var offset: CGFloat = 0
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(colorScheme == .light ? 0.4 : 0.3))
                .frame(width: 35, height: 4)
                .padding(.top, 12)
            
            content
                .padding(.top, 20)
            
            Spacer()
        }
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.height
                    offset = translation > 0 ? translation : 0
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        withAnimation(.spring(response: 0.3)) {
                            isPresented = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 45, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    LinearGradient(
                        colors: colorScheme == .light
                        ? [Color.white.opacity(0.05), Color.white.opacity(0.03)]
                        : [Color.white.opacity(0.02), Color.white.opacity(0.01)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 45, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .light ? 0.5 : 0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(colorScheme == .light ? 0.15 : 0.5), radius: 20, x: 0, y: -9)
        )
        .ignoresSafeArea(edges: [.bottom])
    }
}
