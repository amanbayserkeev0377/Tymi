import SwiftUI

final class AppColorManager: ObservableObject {
    static let shared = AppColorManager()
    
    @Published private(set) var selectedColor: HabitIconColor
    @AppStorage("selectedAppColor") private var selectedColorId: String?
    
    private let availableColors: [HabitIconColor] = [
        .primary,
        .red,
        .orange,
        .yellow,
        .mint,
        .green,
        .blue,
        .purple,
        .softLavender,
        .pink,
        .sky,
        .brown,
        .gray,
        .colorPicker
    ]
    
    private init() {
        selectedColor = .primary
        
        if let savedColorId = selectedColorId,
           let color = HabitIconColor(rawValue: savedColorId) {
            selectedColor = color
        }
    }
    
    func setAppColor(_ color: HabitIconColor) {
        selectedColor = color
        selectedColorId = color.rawValue
    }
    
    func getAvailableColors() -> [HabitIconColor] {
        return availableColors
    }
} 
