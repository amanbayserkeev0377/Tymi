import SwiftUI


struct AboutSection: View {
    @State private var showingAboutSettings = false
    
    var body: some View {
        Button {
            showingAboutSettings = true
        } label: {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.primary)
                    .frame(width: 24, height: 24)
                
                Text("About")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
        .sheet(isPresented: $showingAboutSettings) {
            AboutSettingsView()
                .presentationDetents([.fraction(0.8)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(40)
                .presentationBackground {
                    let cornerRadius: CGFloat = 40
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                    }
                }
        }
    }
}


struct AboutSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        // Rate App
                        AboutRow(
                            title: "Rate App",
                            iconName: "star.fill",
                            iconColor: .primary
                        ) {
                            if let url = URL(string: "https://apps.apple.com/app/idXXXXXXXXXX") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Share App
                        AboutRow(
                            title: "Share App",
                            iconName: "square.and.arrow.up",
                            iconColor: .primary
                        ) {
                            let activityVC = UIActivityViewController(
                                activityItems: ["Check out Tymi app!"],
                                applicationActivities: nil
                            )
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first,
                               let rootVC = window.rootViewController {
                                rootVC.present(activityVC, animated: true)
                            }
                        }
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Contact Developer
                        AboutRow(
                            title: "Contact Developer",
                            iconName: "ellipsis.message",
                            iconColor: .primary
                        ) {
                            if let url = URL(string: "https://t.me/amanbayserkeev0377") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Report a Bug
                        AboutRow(
                            title: "Report a Bug",
                            iconName: "ladybug",
                            iconColor: .primary
                        ) {
                            if let url = URL(string: "mailto:support@tymi.app?subject=Bug%20Report") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Terms of Service
                        AboutRow(
                            title: "Terms of Service",
                            iconName: "text.page",
                            iconColor: .primary
                        ) {
                            if let url = URL(string: "https://tymi.app/terms") {
                                UIApplication.shared.open(url)
                            }
                        }
                        
                        Divider()
                            .padding(.leading, 48)
                        
                        // Privacy Policy
                        AboutRow(
                            title: "Privacy Policy",
                            iconName: "text.document",
                            iconColor: .primary
                        ) {
                            if let url = URL(string: "https://tymi.app/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colorScheme == .dark
                                            ? Color.white.opacity(0.1)
                                            : Color.black.opacity(0.1),
                                            lineWidth: 0.5)
                            )
                            .shadow(radius: 0.5)
                    )
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Версия приложения (внизу)
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                }
                
                Spacer(minLength: 40)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AboutRow: View {
    let title: String
    let iconName: String
    let iconColor: Color
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .tint(.primary)
    }
}
