import SwiftUI

struct ThemeOption {
    let name: String
    let iconName: String
    
    static let system = ThemeOption(name: "System", iconName: "iphone")
    static let light = ThemeOption(name: "Light", iconName: "sun.max")
    static let dark = ThemeOption(name: "Dark", iconName: "moon")
    
    static let allOptions = [system, light, dark]
}

struct AppearanceSection: View {
    @AppStorage("themeMode") private var themeMode: Int = 0 // 0 - System, 1 - Light, 2 - Dark
    
    var body: some View {
        HStack {
            Image(systemName: "swirl.circle.righthalf.filled.inverse")
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
            
            Text("Appearance")
                .foregroundStyle(.primary)
            
            Spacer()
            
            Menu {
                ForEach(0..<ThemeOption.allOptions.count, id: \.self) { index in
                    Button(action: {
                        themeMode = index
                    }) {
                        HStack {
                            Image(systemName: ThemeOption.allOptions[index].iconName)
                                .foregroundStyle(.primary)
                            Text(ThemeOption.allOptions[index].name)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(ThemeOption.allOptions[themeMode].name)
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundStyle(.secondary)
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

struct AppearanceSection_Previews: PreviewProvider {
    static var previews: some View {
        AppearanceSection()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
