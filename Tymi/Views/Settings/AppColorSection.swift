import SwiftUI

struct AppColorSection: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        NavigationLink {
            AppColorPickerView()
        } label: {
            HStack {
                Label("app_color".localized, systemImage: "paintpalette")
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(colorManager.selectedColor.color)
                    .frame(width: 18, height: 18)
            }
        }
    }
}

struct AppColorPickerView: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @State private var customColor = HabitIconColor.customColor
    
    private let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(colorManager.getAvailableColors(), id: \.rawValue) { color in
                    if color == .colorPicker {
                        ColorPicker("", selection: $customColor)
                            .labelsHidden()
                            .onChange(of: customColor) { _, newColor in
                                HabitIconColor.customColor = newColor
                                colorManager.setAppColor(.colorPicker)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(.primary, lineWidth: 2)
                                    .opacity(colorManager.selectedColor == .colorPicker ? 1 : 0)
                            )
                    } else {
                        Button {
                            colorManager.setAppColor(color)
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.primary, lineWidth: 2)
                                            .opacity(colorManager.selectedColor == color ? 1 : 0)
                                    )
                                    .background(
                                        Circle()
                                            .fill(color.color.opacity(0.2))
                                            .frame(width: 50, height: 50)
                                    )
                                
                                Text(color.rawValue.localized)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("choose_color".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
} 
