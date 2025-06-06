import SwiftUI

struct ThemeOption {
    let name: String
    let iconName: String
    
    static let system = ThemeOption(name: "appearance_system".localized, iconName: "iphone")
    static let light = ThemeOption(name: "appearance_light".localized, iconName: "sun.max")
    static let dark = ThemeOption(name: "appearance_dark".localized, iconName: "moon.stars")
    
    static let allOptions = [system, light, dark]
}

struct AppearanceSection: View {
    @AppStorage("themeMode") private var themeMode: ThemeMode = .system
    
    var body: some View {
        HStack {
            Label(
                title: { Text("appearance".localized) },
                icon: {
                    Image(systemName: "swirl.circle.righthalf.filled.inverse")
                        .withIOSSettingsIcon(lightColors: [
                            Color(#colorLiteral(red: 0.4274509804, green: 0.5019607843, blue: 0.6823529412, alpha: 1)),
                            Color(#colorLiteral(red: 0.1490196078, green: 0.2196078431, blue: 0.3568627451, alpha: 1))
                        ])
                }
            )
            
            Spacer()
            
            // Показываем текущую выбранную тему с меню
            Menu {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Button {
                        themeMode = mode
                    } label: {
                        HStack {
                            Image(systemName: ThemeOption.allOptions[mode.rawValue].iconName)
                                .frame(width: 24, alignment: .leading)
                            
                            Text(ThemeOption.allOptions[mode.rawValue].name)
                            
                            Spacer()
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(ThemeOption.allOptions[themeMode.rawValue].name)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }
            }
            .tint(.primary)
        }
    }
}

struct ThemeHelper {
    static func colorSchemeFromThemeMode(_ themeMode: Int) -> ColorScheme? {
        switch themeMode {
        case 0: return nil        // System
        case 1: return .light     // Light
        case 2: return .dark      // Dark
        default: return nil
        }
    }
}
