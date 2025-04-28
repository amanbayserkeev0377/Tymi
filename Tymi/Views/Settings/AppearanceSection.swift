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
            
            Text("Appearance")
                .foregroundStyle(.primary)
            
            Spacer()
            
            Picker("", selection: $themeMode) {
                ForEach(0..<ThemeOption.allOptions.count, id: \.self) { index in
                    HStack {
                        Image(systemName: ThemeOption.allOptions[index].iconName)
                            .foregroundStyle(.primary)
                        Text(ThemeOption.allOptions[index].name).tag(index)
                    }
                }
            }
            .pickerStyle(.menu)
            .tint(.primary)
            .labelsHidden()
        }
        .frame(height: 37)
    }
}

#Preview {
    AppearanceSection()
        .padding()
        .previewLayout(.sizeThatFits)
}
