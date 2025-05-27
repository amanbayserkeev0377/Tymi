import SwiftUI

struct AppColorSection: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        NavigationLink {
            AppColorPickerView()
        } label: {
            HStack {
                Label(
                    title: { Text("app_color".localized) },
                    icon: {
                        Image(systemName: "paintbrush.pointed.fill")
                            .withIOSSettingsIcon(lightColors: [
                                Color(#colorLiteral(red: 0.8549019608, green: 0.4392156863, blue: 1, alpha: 1)),
                                Color(#colorLiteral(red: 0.5803921569, green: 0.1176470588, blue: 0.7450980392, alpha: 1))
                            ])
                    }
                )
                
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var isToggleOn = true
    
    private let columns = [
        GridItem(.adaptive(minimum: 40, maximum: 50), spacing: 12)
    ]
    
    var body: some View {
        Form {
            Section {
                // Toggle preview
                Toggle(isOn: $isToggleOn.animation()) {
                    Label("reminders".localized, systemImage: "bell.badge")
                        .symbolEffect(.bounce, options: .repeat(1), value: isToggleOn)
                }
                .withToggleColor()
                
                // Buttons preview
                HStack {
                    Button("close".localized) {}
                        .tint(colorManager.selectedColor.color)
                    
                    Spacer()
                    
                    Button("edit".localized) {}
                        .tint(colorManager.selectedColor.color)
                    
                    Spacer()
                    
                    Button("done".localized) {}
                        .tint(colorManager.selectedColor.color)
                }
                .listRowInsets(EdgeInsets())
                .padding(.horizontal)
                
                // Complete button preview
                Button(action: {}) {
                    Text("complete".localized)
                        .font(.headline)
                        .foregroundStyle(
                            colorScheme == .dark ? .black : .white
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            AppColorManager.shared.selectedColor.color.opacity(0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .listRowInsets(EdgeInsets())
                .padding()
            } header: {
                Text("preview".localized)
            }
            
            Section {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(colorManager.getAvailableColors(), id: \.rawValue) { color in
                        if color == .colorPicker {
                            ColorPicker("", selection: $customColor)
                                .labelsHidden()
                                .onChange(of: customColor) { _, newColor in
                                    HabitIconColor.customColor = newColor
                                    colorManager.setAppColor(.colorPicker)
                                }
                                .frame(width: 32, height: 32)
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
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    colorManager.setAppColor(color)
                                }
                            } label: {
                                ZStack {
                                    // Background circle with opacity
                                    Circle()
                                        .fill(color.color.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                    
                                    // Main color circle
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(.secondary.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    // Selection indicator
                                    Circle()
                                        .strokeBorder(color.color, lineWidth: 2)
                                        .frame(width: 36, height: 36)
                                        .opacity(colorManager.selectedColor == color ? 1 : 0)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("colors".localized)
            }
        }
        .navigationTitle("app_color".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
