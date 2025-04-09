import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // General Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("General")
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        
                        SettingsRow(
                            title: "Notifications",
                            icon: "bell.fill"
                        ) {
                            // Action
                        }
                        
                        SettingsRow(
                            title: "Appearance",
                            icon: "paintbrush.fill"
                        ) {
                            // Action
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // Contact Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Us")
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        
                        SettingsRow(
                            title: "Email",
                            icon: "envelope.fill"
                        ) {
                            // Action
                        }
                        
                        SettingsRow(
                            title: "Twitter",
                            icon: "message.fill"
                        ) {
                            // Action
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Other Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Other")
                            .font(.headline)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                        
                        SettingsRow(
                            title: "About",
                            icon: "info.circle.fill"
                        ) {
                            // Action
                        }
                        
                        SettingsRow(
                            title: "Privacy Policy",
                            icon: "lock.fill"
                        ) {
                            // Action
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            SettingsView(isPresented: .constant(true))
        }
    }
    .preferredColorScheme(.dark)
} 
