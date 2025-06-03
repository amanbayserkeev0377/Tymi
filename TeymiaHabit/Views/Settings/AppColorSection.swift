import SwiftUI

struct AppColorSection: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @Environment(ProManager.self) private var proManager
    @State private var showingPaywall = false
    
    var body: some View {
        if proManager.isPro {
            // Pro users - normal navigation
            NavigationLink {
                AppColorPickerView()
            } label: {
                HStack {
                    Label(
                        title: { Text("app_color".localized) },
                        icon: {
                            Image(systemName: "paintbrush.pointed.fill")
                                .withIOSSettingsIcon(lightColors: [
                                    Color(.purple),
                                    Color(.pink)
                                ])
                        }
                    )
                    
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(colorManager.selectedColor.color)
                        .frame(width: 18, height: 18)
                        .animation(.easeInOut(duration: 0.3), value: colorManager.selectedColor)
                }
            }
        } else {
            // Free users - show Pro badge and paywall
            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Label(
                        title: { Text("app_color".localized) },
                        icon: {
                            Image(systemName: "paintbrush.pointed.fill")
                                .withIOSSettingsIcon(lightColors: [
                                    Color(.purple),
                                    Color(.pink)
                                ])
                        }
                    )
                    
                    Spacer()
                    
                    ProLockBadge()
                }
            }
            .tint(.primary)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }
}

struct AppColorPickerView: View {
    @ObservedObject private var colorManager = AppColorManager.shared
    @State private var customColor = HabitIconColor.customColor
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var isToggleOn = true
    
    private let columns = [
        GridItem(.adaptive(minimum: 40, maximum: 50), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Toggle preview
                    Toggle(isOn: $isToggleOn.animation(.easeInOut(duration: 0.3))) {
                        Label("reminders".localized, systemImage: "bell.badge")
                            .symbolEffect(.bounce, options: .repeat(1), value: isToggleOn)
                    }
                    .withToggleColor()
                    .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor.color)
                    
                    // Icons preview
                    HStack(spacing: 24) {
                        ForEach(["trophy", "calendar.badge.clock", "cloud.sun", "folder"], id: \.self) { iconName in
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundStyle(colorManager.selectedColor.color)
                                    .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor.color)
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 12)
                    
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
                                colorManager.selectedColor.color.opacity(0.8),
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                            .animation(.easeInOut(duration: 0.5), value: colorManager.selectedColor.color)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding()
                } header: {
                    Text("app_color_preview_header".localized)
                } footer: {
                    Text("app_color_preview_footer".localized)
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
                                    // Haptic feedback
                                    HapticManager.shared.playSelection()
                                    withAnimation(.easeInOut(duration: 0.5)) {
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
                    Text("app_color_colors_header".localized)
                }
            }
            .navigationTitle("app_color".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDragIndicator(.visible)
    }
}
