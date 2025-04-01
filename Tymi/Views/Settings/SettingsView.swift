import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Sections
            VStack(spacing: 16) {
                // App Info Section
                VStack(spacing: 0) {
                    Button {
                        // Open App Store
                    } label: {
                        HStack {
                            Label("Rate App", systemImage: "star")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    Button {
                        // Share App
                    } label: {
                        HStack {
                            Label("Share App", systemImage: "square.and.arrow.up")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                    }
                }
                .glassCard()
                
                // Support Section
                VStack(spacing: 0) {
                    Button {
                        // Contact Support
                    } label: {
                        HStack {
                            Label("Contact Support", systemImage: "envelope")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                    
                    Button {
                        // Privacy Policy
                    } label: {
                        HStack {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(16)
                    }
                }
                .glassCard()
            }
            .padding(.horizontal, 24)
            
            // Version
            Text("Version 1.0.0")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 24)
        .modalStyle(isPresented: $isPresented)
    }
} 
