import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        List {
            // General Section
            Section("General") {
                SettingsRow(
                    title: "Notifications",
                    icon: "bell.fill",
                    iconColor: .blue
                ) {
                    // Handle notifications
                }
                
                SettingsRow(
                    title: "Appearance",
                    icon: "paintbrush.fill",
                    iconColor: .purple
                ) {
                    // Handle appearance
                }
            }
            
            // Contact Us Section
            Section("Contact Us") {
                SettingsRow(
                    title: "Email",
                    icon: "envelope.fill",
                    iconColor: .green
                ) {
                    // Handle email
                }
                
                SettingsRow(
                    title: "Twitter",
                    icon: "bird.fill",
                    iconColor: .blue
                ) {
                    // Handle Twitter
                }
            }
            
            // Other Section
            Section("Other") {
                SettingsRow(
                    title: "About",
                    icon: "info.circle.fill",
                    iconColor: .blue
                ) {
                    // Handle about
                }
                
                SettingsRow(
                    title: "Privacy Policy",
                    icon: "hand.raised.fill",
                    iconColor: .red
                ) {
                    // Handle privacy policy
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
}
