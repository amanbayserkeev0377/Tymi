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
                        .symbolEffect(.bounce, options: .repeat(1), value: hapticsEnabled)
                }
            )
        }
        .tint(colorScheme == .dark ? Color.gray.opacity(0.8) : .primary)
    }
}
