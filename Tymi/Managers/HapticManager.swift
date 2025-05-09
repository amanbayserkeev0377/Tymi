import SwiftUI
import UIKit 

class HapticManager {
    static let shared = HapticManager()
    
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    
    private init() {}
    
    // MARK: - View Modifiers
    
    func sensoryFeedback(_ feedback: SensoryFeedback, trigger: Bool) -> some ViewModifier {
        SensoryFeedbackModifier(
            feedback: feedback,
            trigger: trigger,
            isEnabled: hapticsEnabled
        )
    }
    
    // MARK: - Direct Haptic Methods
    
    func play(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(feedbackType)
    }
    
    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func playSelection() {
        guard hapticsEnabled else { return }
        
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Helper Modifier
private struct SensoryFeedbackModifier: ViewModifier {
    let feedback: SensoryFeedback
    let trigger: Bool
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sensoryFeedback(feedback, trigger: trigger)
        } else {
            content
        }
    }
}

// MARK: - View Extensions
extension View {

    func hapticFeedback(_ feedback: SensoryFeedback, trigger: Bool) -> some View {
        modifier(HapticManager.shared.sensoryFeedback(feedback, trigger: trigger))
    }
    
    func successHaptic(trigger: Bool) -> some View {
        hapticFeedback(.success, trigger: trigger)
    }
    
    func errorHaptic(trigger: Bool) -> some View {
        hapticFeedback(.error, trigger: trigger)
    }
    
    func selectionHaptic(trigger: Bool) -> some View {
        hapticFeedback(.selection, trigger: trigger)
    }
    
    func increaseHaptic(trigger: Bool) -> some View {
        hapticFeedback(.increase, trigger: trigger)
    }
    
    func decreaseHaptic(trigger: Bool) -> some View {
        hapticFeedback(.decrease, trigger: trigger)
    }
}
