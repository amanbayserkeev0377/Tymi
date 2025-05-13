import SwiftUI

struct IconSection: View {
    @Binding var selectedIcon: String?
    @State private var showIconPicker = false
    
    var body: some View {
        Button {
            showIconPicker = true
        } label: {
            HStack {
                Label("icon".localized, systemImage: selectedIcon ?? "questionmark")
                
                Spacer()
                        
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
            }
            .presentationDetents([.fraction(0.7)])
            .presentationDragIndicator(.visible)
        }
    }
}
