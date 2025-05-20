import SwiftUI
import UIKit

// MARK: - AppIcon Enum
// Defines app icons with their properties and localized names
enum AppIcon: Hashable, Identifiable {
    // MARK: - Cases
    case main           // Default app icon
    case light(name: String)
    case dark(name: String)
    case dream(name: String)
    case bliss(name: String)
    case blaze(name: String)
    case aura(name: String)
    case chill(name: String)
    case minimalLight(name: String)
    case minimalDark(name: String)
    case sunrise(name: String)
    case paper(name: String)
    case silverBlue(name: String)
    
    // MARK: - All Icons
    // List of all available icons
    static let allIcons: [AppIcon] = [
        .main,
        .light(name: "AppIconLight"),
        .dark(name: "AppIconDark"),
        .dream(name: "AppIconDream"),
        .bliss(name: "AppIconBliss"),
        .blaze(name: "AppIconBlaze"),
        .aura(name: "AppIconAura"),
        .chill(name: "AppIconChill"),
        .minimalLight(name: "AppIconMinimalLight"),
        .minimalDark(name: "AppIconMinimalDark"),
        .sunrise(name: "AppIconSunrise"),
        .paper(name: "AppIconPaper"),
        .silverBlue(name: "AppIconSilverBlue")
    ]
    
    // MARK: - ID
    // Unique identifier for each icon
    var id: String {
        switch self {
        case .main: return "main"
        case .light(let name): return name
        case .dark(let name): return name
        case .dream(let name): return name
        case .bliss(let name): return name
        case .blaze(let name): return name
        case .aura(let name): return name
        case .chill(let name): return name
        case .minimalLight(let name): return name
        case .minimalDark(let name): return name
        case .sunrise(let name): return name
        case .paper(let name): return name
        case .silverBlue(let name): return name
        }
    }
    
    // MARK: - AppIconSet Name
    // Name for AppIconSet in Assets.xcassets (nil for default icon)
    var name: String? {
        switch self {
        case .main: return nil
        case .light(let name): return name
        case .dark(let name): return name
        case .dream(let name): return name
        case .bliss(let name): return name
        case .blaze(let name): return name
        case .aura(let name): return name
        case .chill(let name): return name
        case .minimalLight(let name): return name
        case .minimalDark(let name): return name
        case .sunrise(let name): return name
        case .paper(let name): return name
        case .silverBlue(let name): return name
        }
    }
    
    // MARK: - Preview Image
    // Name for ImageSet in Assets.xcassets for UI preview
    var preview: String {
        switch self {
        case .main: return "app_icon_main"
        case .light(_): return "app_icon_light"
        case .dark(_): return "app_icon_dark"
        case .dream(_): return "app_icon_dream"
        case .bliss(_): return "app_icon_bliss"
        case .blaze(_): return "app_icon_blaze"
        case .aura(_): return "app_icon_aura"
        case .chill(_): return "app_icon_chill"
        case .minimalLight(_): return "app_icon_minimal_light"
        case .minimalDark(_): return "app_icon_minimal_dark"
        case .sunrise(_): return "app_icon_sunrise"
        case .paper(_): return "app_icon_paper"
        case .silverBlue(_): return "app_icon_silver_blue"
        }
    }
    
    // MARK: - Localized Display Name
    // Localized name for UI display
    var displayName: String {
        switch self {
        case .main: return "app_icon_main_name".localized
        case .light(_): return "app_icon_light_name".localized
        case .dark(_): return "app_icon_dark_name".localized
        case .dream(_): return "app_icon_dream_name".localized
        case .bliss(_): return "app_icon_bliss_name".localized
        case .blaze(_): return "app_icon_blaze_name".localized
        case .aura(_): return "app_icon_aura_name".localized
        case .chill(_): return "app_icon_chill_name".localized
        case .minimalLight(_): return "app_icon_minimal_light_name".localized
        case .minimalDark(_): return "app_icon_minimal_dark_name".localized
        case .sunrise(_): return "app_icon_sunrise_name".localized
        case .paper(_): return "app_icon_paper_name".localized
        case .silverBlue(_): return "app_icon_silver_blue_name".localized
        }
    }
}

// MARK: - AppIconManager Class
// Manages app icon switching and UI updates
class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    
    // Current icon for UI updates
    @Published private(set) var currentIcon: AppIcon
    
    private init() {
        currentIcon = Self.getCurrentAppIcon()
    }
    
    // Gets the currently set app icon
    static func getCurrentAppIcon() -> AppIcon {
        if let alternateIconName = UIApplication.shared.alternateIconName {
            if let matchingIcon = AppIcon.allIcons.first(where: { $0.name == alternateIconName }) {
                return matchingIcon
            }
        }
        return .main
    }
    
    // Sets a new app icon
    func setAppIcon(_ icon: AppIcon) {
        print("Setting icon: \(icon.id)")
        applySpecificIcon(icon.name)
        currentIcon = icon
    }
    
    // Applies the specified icon
    private func applySpecificIcon(_ iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Device does not support alternate icons")
            return
        }
        
        let currentIconName = UIApplication.shared.alternateIconName
        
        // Skip if the icon is already set
        if currentIconName == iconName {
            print("Icon \(String(describing: iconName)) is already set")
            return
        }
        
        // Apply the icon
        UIApplication.shared.setAlternateIconName(iconName) { [weak self] error in
            if let error = error {
                print("Error setting icon: \(error.localizedDescription)")
            } else {
                print("Successfully set icon: \(String(describing: iconName))")
                if let self = self {
                    Task { @MainActor in
                        self.currentIcon = Self.getCurrentAppIcon()
                    }
                }
            }
        }
    }
}
