import SwiftUI

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