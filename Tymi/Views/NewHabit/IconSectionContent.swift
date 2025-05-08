import SwiftUI

struct IconSectionContent: View {
    @Binding var selectedIcon: String?
    @State private var isIconPickerPresented = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            isIconPickerPresented = true
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                
                if let iconName = selectedIcon {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "questionmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.primary)
        .sheet(isPresented: $isIconPickerPresented) {
            IconPickerView(selectedIcon: $selectedIcon)
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationBackground {
                    ZStack {
                        Rectangle().fill(.ultraThinMaterial)
                    }
                }
        }
    }
} 