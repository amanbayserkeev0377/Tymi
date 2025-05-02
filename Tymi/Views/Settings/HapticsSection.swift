import SwiftUI

struct HapticsSection: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
            
            Text("haptics".localized)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Toggle("", isOn: $hapticsEnabled)
                .labelsHidden()
                .tint(colorScheme == .dark ? Color.gray : .black)
                .modifier(HapticManager.shared.sensoryFeedback(.selection, trigger: hapticsEnabled))
        }
    }
}
