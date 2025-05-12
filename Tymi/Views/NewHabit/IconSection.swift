import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @State private var showIconPicker = false
    
    var body: some View {
        Button {
            showIconPicker = true
        } label: {
            HStack {
                Image(systemName: selectedIcon ?? "questionmark")
                    .font(.body)
                    .foregroundStyle(selectedIcon != nil ? .primary : .secondary)
                    .accessibilityHidden(true)
                
                // Текст
                Text("icon".localized)
                
                Spacer()
                
                // Индикатор кнопки
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showIconPicker) {
            NavigationStack {
                IconPickerView(selectedIcon: $selectedIcon)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("done".localized) {
                                showIconPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
        }
    }
}
