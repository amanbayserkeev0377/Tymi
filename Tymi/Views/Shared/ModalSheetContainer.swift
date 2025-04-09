import SwiftUI

struct ModalSheetContainer<Content: View>: View {
    let title: String?
    let detents: [PresentationDetent]
    let showsDragIndicator: Bool
    let content: () -> Content
    
    init(
        title: String? = nil,
        detents: [PresentationDetent] = [.large],
        showsDragIndicator: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.detents = detents
        self.showsDragIndicator = showsDragIndicator
        self.content = content
    }
    
    var body: some View {
        NavigationStack {
            content()
                .navigationTitle(title ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .scrollDismissesKeyboard(.interactively)
                .background(Color(.systemGroupedBackground))
        }
        .presentationDetents(Set(detents))
        .presentationDragIndicator(showsDragIndicator ? .visible : .hidden)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ModalSheetContainer(title: "Example") {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(0..<10) { i in
                            Text("Item \(i)")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                }
            }
        }
} 