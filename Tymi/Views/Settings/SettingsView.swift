import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @AppStorage("enableReminders") private var enableReminders = false
    @State private var selectedSection: SettingsSection? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            SettingsHeaderView(isPresented: $isPresented)
            
            if let section = selectedSection {
                // Show selected section
                ScrollView {
                    VStack(spacing: 24) {
                        // Back button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSection = nil
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.medium))
                                Text("Back")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                        
                        // Section content
                        switch section {
                        case .appearance:
                            AppearanceSectionView()
                                .glassCard()
                        case .notifications:
                            NotificationsSectionView(enableReminders: $enableReminders)
                                .glassCard()
                        case .support:
                            SupportSectionView()
                                .glassCard()
                        }
                        
                        Spacer(minLength: 32)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                // Show sections list
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(SettingsSection.allCases, id: \.self) { section in
                            SectionButton(section: section) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedSection = section
                                }
                            }
                        }
                        
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 24)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .tint(colorScheme == .dark ? .white : .black)
    }
}

// MARK: - SettingsSection
enum SettingsSection: CaseIterable {
    case appearance
    case notifications
    case support
    
    var title: String {
        switch self {
        case .appearance: return "Appearance"
        case .notifications: return "Notifications"
        case .support: return "Support"
        }
    }
    
    var icon: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .notifications: return "bell.fill"
        case .support: return "questionmark.circle.fill"
        }
    }
}

// MARK: - SectionButton
struct SectionButton: View {
    let section: SettingsSection
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: section.icon)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                
                Text(section.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SettingsHeaderView
struct SettingsHeaderView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack {
            Text("Settings")
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)
            
            Spacer()
            
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
        .padding(.top, 24)
    }
}

// MARK: - AppearanceSectionView
struct AppearanceSectionView: View {
    @StateObject private var viewModel = AppearanceSettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section Header
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text("Appearance")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            // Dark Mode
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Text("Dark Mode")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                
                HStack(spacing: 12) {
                    ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                        Text(preference.title)
                            .font(.subheadline.weight(.medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.colorSchemePreference == preference ? .white.opacity(0.2) : .clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                            )
                            .foregroundStyle(.primary)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.colorSchemePreference = preference
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                    }
                }
            }
            
            // App Icon
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "app.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Text("App Icon")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                
                // Icon Preview
                HStack(spacing: 24) {
                    ForEach(AppIconPreference.allCases, id: \.self) { preference in
                        AppIconOptionView(
                            preference: preference,
                            colorScheme: colorScheme,
                            isSelected: viewModel.appIconPreference == preference,
                            isChanging: viewModel.isChangingIcon && viewModel.appIconPreference == preference,
                            onTap: {
                                guard !viewModel.isChangingIcon else { return }
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.appIconPreference = preference
                                }
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        )
                    }
                }
                
                if let error = viewModel.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - NotificationsSectionView
struct NotificationsSectionView: View {
    @Binding var enableReminders: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section Header
            HStack {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text("Notifications")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            // Enable Reminders Toggle
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text("Enable Reminders")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: $enableReminders)
                    .labelsHidden()
                    .tint(.purple)
            }
            
            // Time Picker Placeholder
            if enableReminders {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Text("Reminder Time")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("9:00 AM")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .systemBackground).opacity(0.5))
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
            }
        }
    }
}

// MARK: - SupportSectionView
struct SupportSectionView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section Header
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text("Support")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                SupportButton(title: "Send Feedback", icon: "envelope.fill") {
                    print("Send Feedback tapped")
                }
                
                SupportButton(title: "Rate on App Store", icon: "star.fill") {
                    print("Rate on App Store tapped")
                }
                
                SupportButton(title: "Visit Website", icon: "globe") {
                    print("Visit Website tapped")
                }
                
                SupportButton(title: "Follow on X", icon: "x.circle.fill") {
                    print("Follow on X tapped")
                }
                
                SupportButton(title: "Follow on Instagram", icon: "camera.fill") {
                    print("Follow on Instagram tapped")
                }
            }
        }
    }
}

// MARK: - SupportButton
struct SupportButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemBackground).opacity(0.5))
                    .background(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AppIconOptionView
struct AppIconOptionView: View {
    let preference: AppIconPreference
    let colorScheme: ColorScheme
    let isSelected: Bool
    let isChanging: Bool
    let onTap: () -> Void
    
    var body: some View {
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
                
                if isChanging {
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
            .pulseEffect(isSelected: isSelected)
            
            Text(preference.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .opacity(isSelected ? 1 : 0.5)
        .scaleEffect(isSelected ? 1 : 0.95)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
        .onTapGesture(perform: onTap)
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
