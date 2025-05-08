import SwiftUI

struct HapticsSection: View {
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "waveform")
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
                .symbolEffect(.bounce, options: .repeat(1), value: hapticsEnabled)
            
            Text("haptics".localized)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Toggle("", isOn: $hapticsEnabled.animation(.easeInOut(duration: 0.3)))
                .labelsHidden()
                .tint(colorScheme == .dark ? Color.gray : .black)
        }
    }
}
