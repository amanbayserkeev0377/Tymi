import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = AppearanceSettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    // Dark Mode
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .font(.title2)
                            Text("Dark Mode")
                                .font(.title3.weight(.semibold))
                        }
                        
                        Picker("Dark Mode", selection: $viewModel.colorSchemePreference) {
                            ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                                Text(preference.title).tag(preference)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.colorSchemePreference) { _ in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // App Icon
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "app.fill")
                                .font(.title2)
                            Text("App Icon")
                                .font(.title3.weight(.semibold))
                        }
                        
                        // Icon Preview
                        HStack(spacing: 24) {
                            ForEach(AppIconPreference.allCases, id: \.self) { preference in
                                VStack(spacing: 8) {
                                    ZStack {
                                        if preference == .automatic {
                                            Image(colorScheme == .dark ? "Tymi_dark" : "Tymi_light")
                                                .resizable()
                                                .frame(width: 60, height: 60)
                                        } else {
                                            Image(preference == .light ? "Tymi_light" : "Tymi_dark")
                                                .resizable()
                                                .frame(width: 60, height: 60)
                                        }
                                        
                                        if viewModel.isChangingIcon && viewModel.appIconPreference == preference {
                                            Color(uiColor: .systemBackground)
                                                .opacity(0.7)
                                            
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                    .pulseEffect(isSelected: viewModel.appIconPreference == preference)
                                    
                                    Text(preference.title)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .opacity(viewModel.appIconPreference == preference ? 1 : 0.5)
                                .scaleEffect(viewModel.appIconPreference == preference ? 1 : 0.95)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.appIconPreference)
                                .onTapGesture {
                                    guard !viewModel.isChangingIcon else { return }
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.appIconPreference = preference
                                    }
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if let error = viewModel.lastError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 8)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.lastError)
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                    }
                    .buttonStyle(GlassButtonStyle(size: 44))
                }
            }
        }
    }
} 
