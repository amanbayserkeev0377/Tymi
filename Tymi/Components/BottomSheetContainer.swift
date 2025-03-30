import SwiftUI

struct BottomSheetContainer<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(0)
                
                VStack {
                    Spacer()
                    BottomSheetView(isPresented: $isPresented) {
                        content
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }
            }
        }
        .animation(.spring(response: 0.3), value: isPresented)
    }
}
