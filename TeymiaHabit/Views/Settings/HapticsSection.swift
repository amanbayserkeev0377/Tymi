import SwiftUI

struct HapticsSection: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Toggle(isOn: $hapticsEnabled.animation(.easeInOut(duration: 0.3))) {
            Label(
                title: { Text("haptics".localized) },
                icon: {
                    Image(systemName: "waveform")
                        .withIOSSettingsIcon(lightColors: [
                            Color(#colorLiteral(red: 1, green: 0.7019607843, blue: 0.2666666667, alpha: 1)),
                            Color(#colorLiteral(red: 0.7333333333, green: 0.3568627451, blue: 0.0, alpha: 1))
                        ])
                        .symbolEffect(.bounce, options: .repeat(1), value: hapticsEnabled)
                }
            )
        }
        .withToggleColor()
    }
}
