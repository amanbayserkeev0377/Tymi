import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            Color.black.opacity(0.05)
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.medium))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // MARK: - Feedback & Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Feedback & Info")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 24)
                            
                            GlassSectionBackground {
                                VStack(spacing: 1) {
                                    SettingsRowView(
                                        icon: "star.fill",
                                        title: "Rate Tymi",
                                        hasChevron: true,
                                        action: viewModel.openAppStore
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    SettingsRowView(
                                        icon: "envelope.fill",
                                        title: "Send Feedback",
                                        hasChevron: true,
                                        action: viewModel.openEmail
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    SettingsRowView(
                                        icon: "link",
                                        title: "Follow us on X",
                                        hasChevron: true,
                                        action: viewModel.openX
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    SettingsRowView(
                                        icon: "camera.fill",
                                        title: "Follow us on Instagram",
                                        hasChevron: true,
                                        action: viewModel.openInstagram
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    SettingsRowView(
                                        icon: "safari.fill",
                                        title: "Visit Website",
                                        hasChevron: true,
                                        action: viewModel.openWebsite
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                        
                        // MARK: - Notifications Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notifications")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 24)
                            
                            GlassSectionBackground {
                                VStack(spacing: 1) {
                                    SettingsRowView(
                                        icon: "bell.fill",
                                        title: "Enable Reminders",
                                        toggleBinding: viewModel.isRemindersEnabled
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .tint(.black)
    }
} 