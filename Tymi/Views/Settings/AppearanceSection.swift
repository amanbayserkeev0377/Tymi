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
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    
    var body: some View {
        HStack {
            Label(
                title: { Text("appearance".localized) },
                icon: { Image(systemName: "swirl.circle.righthalf.filled.inverse") }
            )
            
            Spacer()
            
            // Показываем текущую выбранную тему с меню
            Menu {
                ForEach(0..<ThemeOption.allOptions.count, id: \.self) { index in
                    Button {
                        themeMode = index
                    } label: {
                        HStack {
                            Image(systemName: ThemeOption.allOptions[index].iconName)
                                .frame(width: 24, alignment: .leading)
                            
                            Text(ThemeOption.allOptions[index].name)
                            
                            Spacer()
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(ThemeOption.allOptions[themeMode].name)
                        .foregroundStyle(.secondary)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
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
