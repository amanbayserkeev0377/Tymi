import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @AppStorage("enableReminders") private var enableReminders = false
    @AppStorage("enableAppBadge") private var enableAppBadge = false
    @AppStorage("firstWeekday") private var firstWeekday = 1 // 1 = Sunday, 2 = Monday
    @State private var selectedSection: SettingsSection? = nil
    
    var body: some View {
        ModalView(isPresented: $isPresented, title: "Settings") {
            ZStack {
                VStack(spacing: 0) {
                    VStack(spacing: 24) {
                        // General Section
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "paintbrush.fill",
                                title: "Appearance",
                                action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedSection = .appearance
                                    }
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedSection = .notifications
                                    }
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "globe",
                                title: "Language",
                                action: {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "calendar.badge.clock",
                                title: "First Day of Week",
                                action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedSection = .firstDayOfWeek
                                    }
                                }
                            )
                        }
                        .glassCard()
                        
                        // Contact Us Section
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "envelope.fill",
                                title: "Send Feedback",
                                action: {
                                    print("Send Feedback tapped")
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "star.fill",
                                title: "Rate App",
                                action: {
                                    print("Rate App tapped")
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "globe",
                                title: "Visit Website",
                                action: {
                                    print("Visit Website tapped")
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "x.circle.fill",
                                title: "Follow on X",
                                action: {
                                    print("Follow on X tapped")
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "camera.fill",
                                title: "Follow on Instagram",
                                action: {
                                    print("Follow on Instagram tapped")
                                }
                            )
                        }
                        .glassCard()
                        
                        // Other Section
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "doc.text.fill",
                                title: "Terms of Service",
                                action: {
                                    print("Terms of Service tapped")
                                }
                            )
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            SettingsRow(
                                icon: "lock.fill",
                                title: "Privacy Policy",
                                action: {
                                    print("Privacy Policy tapped")
                                }
                            )
                        }
                        .glassCard()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top)
                    
                    Spacer()
                }
                
                // Section Views
                if let section = selectedSection {
                    VStack(spacing: 0) {
                        HStack {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedSection = nil
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.medium))
                            }
                            .buttonStyle(GlassButtonStyle(size: 35))
                            
                            Spacer()
                            
                            Text(section.title)
                                .font(.title3.weight(.semibold))
                            
                            Spacer()
                            
                            Color.clear
                                .frame(width: 35, height: 35)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        
                        Divider()
                            .padding(.horizontal, 24)
                        
                        Group {
                            switch section {
                            case .appearance:
                                AppearanceSectionView()
                                    .padding(.top, 16)
                            case .notifications:
                                NotificationsSectionView(enableReminders: $enableReminders)
                                    .padding(.top, 16)
                            case .firstDayOfWeek:
                                FirstDayOfWeekView(firstWeekday: $firstWeekday)
                                    .padding(.top, 16)
                            }
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width - 48)
                    .background(Color.clear)
                    .glassCard()
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }
}

// MARK: - SettingsRow
struct SettingsRow: View {
    let icon: String
    let title: String
    var toggleBinding: Binding<Bool>? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let binding = toggleBinding {
                    Toggle("", isOn: binding)
                        .labelsHidden()
                        .tint(.purple)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - SettingsSection
enum SettingsSection {
    case appearance
    case notifications
    case firstDayOfWeek
    
    var title: String {
        switch self {
        case .appearance: return "Appearance"
        case .notifications: return "Notifications"
        case .firstDayOfWeek: return "First Day of Week"
        }
    }
}

// MARK: - FirstDayOfWeekView
struct FirstDayOfWeekView: View {
    @Binding var firstWeekday: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $firstWeekday) {
                Text("Sunday").tag(1)
                Text("Monday").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - AppearanceSectionView
struct AppearanceSectionView: View {
    @StateObject private var viewModel = AppearanceSettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Dark Mode
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "moon.fill")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text("Dark Mode")
                        .font(.body)
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
                                viewModel.colorSchemePreference = preference
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                    }
                }
            }
            
            // App Icon
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "app.fill")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text("App Icon")
                        .font(.body)
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
                                viewModel.appIconPreference = preference
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
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - NotificationsSectionView
struct NotificationsSectionView: View {
    @Binding var enableReminders: Bool
    @AppStorage("enableAppBadge") private var enableAppBadge = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enable Reminders Toggle
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.body)
                    .foregroundStyle(.primary)
                Text("Enable Reminders")
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: $enableReminders)
                    .labelsHidden()
                    .tint(.purple)
            }
            
            // App Badge Toggle
            HStack {
                Image(systemName: "app.badge.fill")
                    .font(.body)
                    .foregroundStyle(.primary)
                Text("Show App Icon Badge")
                    .font(.body)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Toggle("", isOn: $enableAppBadge)
                    .labelsHidden()
                    .tint(.purple)
            }
            
            // Time Picker Placeholder
            if enableReminders {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text("Reminder Time")
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("9:00 AM")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
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
