import SwiftUI
import Combine

@MainActor
final class AppearanceSettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var colorSchemePreference: ColorSchemePreference
    @Published var appIconPreference: AppIconPreference
    @Published private(set) var isChangingIcon = false
    @Published private(set) var lastError: String?
    
    // MARK: - Private Properties
    private var themeObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init() {
        // Initialize stored properties first
        let storedColorScheme = UserDefaults.standard.string(forKey: "colorSchemePreference") ?? ColorSchemePreference.automatic.rawValue
        let storedAppIcon = UserDefaults.standard.string(forKey: "appIconPreference") ?? AppIconPreference.automatic.rawValue
        
        self.colorSchemePreference = ColorSchemePreference(rawValue: storedColorScheme) ?? .automatic
        self.appIconPreference = AppIconPreference(rawValue: storedAppIcon) ?? .automatic
        
        // Setup observers and initial state after initialization
        setupObservers()
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
        // Observe property changes
        objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                UserDefaults.standard.set(self.colorSchemePreference.rawValue, forKey: "colorSchemePreference")
                UserDefaults.standard.set(self.appIconPreference.rawValue, forKey: "appIconPreference")
            }
            .store(in: &subscriptions)
        
        // Observe system theme changes
        themeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemThemeChange()
        }
    }
    
    private func handleSystemThemeChange() {
        if appIconPreference == .automatic {
            Task { await updateAppIcon() }
        }
    }
    
    private func updateColorScheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first
        else { return }
        
        window.overrideUserInterfaceStyle = colorSchemePreference.colorScheme.map { $0 == .dark ? .dark : .light } ?? .unspecified
    }
    
    private func updateAppIcon() async {
        guard !isChangingIcon else { return }
        
        let iconName: String?
        switch appIconPreference {
        case .automatic:
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first
            else {
                iconName = nil
                break
            }
            iconName = window.traitCollection.userInterfaceStyle == .dark ? "Tymi_dark" : "Tymi_light"
            
        case .light:
            iconName = "Tymi_light"
        case .dark:
            iconName = "Tymi_dark"
        }
        
        // Only change if different from current
        if UIApplication.shared.alternateIconName != iconName {
            do {
                isChangingIcon = true
                lastError = nil
                try await UIApplication.shared.setAlternateIconName(iconName)
            } catch {
                lastError = "Failed to change app icon. Please try again."
                print("Error setting alternate icon: \(error)")
            }
            isChangingIcon = false
        }
    }
    
    // MARK: - Subscriptions
    private var subscriptions = Set<AnyCancellable>()
} 