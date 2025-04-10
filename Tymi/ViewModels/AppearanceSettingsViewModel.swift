import SwiftUI
import Combine

@MainActor
final class AppearanceSettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var colorSchemePreference: ColorSchemePreference {
        didSet {
            if oldValue != colorSchemePreference {
                UserDefaults.standard.set(colorSchemePreference.rawValue, forKey: "colorSchemePreference")
                updateColorScheme()
            }
        }
    }
    
    @Published var appIconPreference: AppIconPreference {
        didSet {
            if oldValue != appIconPreference {
                UserDefaults.standard.set(appIconPreference.rawValue, forKey: "appIconPreference")
                Task { await updateAppIcon() }
            }
        }
    }
    
    @Published private(set) var isChangingIcon = false
    @Published private(set) var lastError: String?
    
    // MARK: - Private Properties
    private var themeObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init() {
        let storedColorScheme = UserDefaults.standard.string(forKey: "colorSchemePreference") ?? ColorSchemePreference.automatic.rawValue
        let storedAppIcon = UserDefaults.standard.string(forKey: "appIconPreference") ?? AppIconPreference.automatic.rawValue
        
        self.colorSchemePreference = ColorSchemePreference(rawValue: storedColorScheme) ?? .automatic
        self.appIconPreference = AppIconPreference(rawValue: storedAppIcon) ?? .automatic
        
        updateColorScheme()
        Task { await updateAppIcon() }
    }
    
    deinit {
        if let observer = themeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Observe system theme changes
        themeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleSystemThemeChange()
            }
        }
    }
    
    private func handleSystemThemeChange() async {
        if appIconPreference == .automatic {
            await updateAppIcon()
        }
    }
    
    private func updateColorScheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else { return }
        
        window.overrideUserInterfaceStyle = colorSchemePreference.colorScheme.map { $0 == .dark ? .dark : .light } ?? .unspecified
    }
    
    private func updateAppIcon() async {
        let iconName = appIconPreference == .automatic ? nil :
            appIconPreference == .light ? "Tymi_light" : "Tymi_dark"
        
        if UIApplication.shared.alternateIconName != iconName {
            try? await UIApplication.shared.setAlternateIconName(iconName)
        }
    }
} 