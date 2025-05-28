import SwiftUI

struct IconPickerView: View {
    // MARK: - Bindings
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    
    // MARK: - State
    @State private var customColor = HabitIconColor.customColor
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // MARK: - Constants
    private let defaultIcon = "checkmark"
    
    // MARK: - Adaptive Properties
    
    /// Icon size based on device and dynamic type
    private var iconSize: CGFloat {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 36 : 42
        let typeMultiplier = dynamicTypeMultiplier
        return baseSize * typeMultiplier
    }
    
    /// Button size based on device and dynamic type
    private var buttonSize: CGFloat {
        let baseSize: CGFloat = horizontalSizeClass == .compact ? 60 : 70
        let typeMultiplier = dynamicTypeMultiplier
        return baseSize * typeMultiplier
    }
    
    /// Dynamic type multiplier for accessibility
    private var dynamicTypeMultiplier: CGFloat {
        switch dynamicTypeSize {
        case .accessibility5: return 1.4
        case .accessibility4: return 1.3
        case .accessibility3: return 1.2
        case .accessibility2, .accessibility1: return 1.1
        case .xxLarge, .xxxLarge: return 1.05
        default: return 1.0
        }
    }
    
    /// Adaptive grid columns
    private var adaptiveColumns: [GridItem] {
        let baseColumnCount = horizontalSizeClass == .compact ? 5 : 8
        // Reduce columns for larger dynamic type
        let adjustedCount = dynamicTypeSize.isAccessibilitySize ? max(3, baseColumnCount - 2) : baseColumnCount
        return Array(repeating: GridItem(.flexible()), count: adjustedCount)
    }
    
    /// Color picker columns
    private var colorColumns: [GridItem] {
        let columnCount = horizontalSizeClass == .compact ? 7 : 10
        return Array(repeating: GridItem(.flexible()), count: columnCount)
    }
    
    // MARK: - Data
    
    private let categories: [IconCategory] = [
        IconCategory(name: "health".localized, icons: [
            "figure.walk", "figure.run", "figure.stairs", "figure.strengthtraining.traditional", "figure.cooldown",
            "figure.mind.and.body", "figure.pool.swim", "shoeprints.fill", "bicycle", "bed.double.fill",
            "brain.fill", "eye.fill", "heart.fill", "lungs.fill", "waterbottle.fill",
            "pills.fill", "testtube.2", "stethoscope", "carrot.fill", "tree.fill"
        ]),
        
        IconCategory(name: "productivity".localized, icons: [
            "brain.head.profile.fill", "clock.fill", "hourglass", "pencil.and.list.clipboard", "pencil.and.scribble",
            "book.fill", "graduationcap.fill", "translate", "function", "chart.pie.fill",
            "checklist", "calendar.badge.clock", "person.2.wave.2.fill", "bubble.left.and.bubble.right.fill", "globe.americas.fill",
            "medal.fill", "macbook", "keyboard.fill", "lightbulb.max.fill", "atom"
        ]),
        
        IconCategory(name: "hobbies".localized, icons: [
            "camera.fill", "play.rectangle.fill", "headphones", "music.note", "film.fill",
            "paintbrush.pointed.fill", "paintpalette.fill", "photo.fill", "theatermasks.fill", "puzzlepiece.extension.fill",
            "pianokeys", "guitars.fill", "rectangle.pattern.checkered", "mountain.2.fill", "drone.fill",
            "playstation.logo", "xbox.logo", "formfitting.gamecontroller.fill", "motorcycle.fill", "scooter",
            "soccerball", "basketball.fill", "volleyball.fill", "tennisball.fill", "tennis.racket"
        ]),
        
        IconCategory(name: "lifestyle".localized, icons: [
            "shower.fill", "bathtub.fill", "sink.fill", "hands.and.sparkles.fill", "washer.fill",
            "fork.knife", "frying.pan.fill", "popcorn.fill", "cup.and.heat.waves.fill", "birthday.cake.fill",
            "cart.fill", "takeoutbag.and.cup.and.straw.fill", "gift.fill", "house.fill", "stroller.fill",
            "face.smiling.fill", "envelope.fill", "phone.fill", "beach.umbrella.fill", "pawprint.fill",
            "creditcard.fill", "banknote.fill", "location.fill", "hand.palm.facing.fill", "steeringwheel.and.hands"
        ])
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            iconGridSection
            colorPickerSection
        }
        .navigationTitle("choose_icon".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("button_done".localized) {
                    dismiss()
                }
            }
        }
        .onAppear {
            if selectedIcon == nil {
                selectedIcon = defaultIcon
            }
        }
    }
    
    // MARK: - View Components
    
    /// Main icon grid section
    private var iconGridSection: some View {
        List {
            ForEach(categories, id: \.name) { category in
                Section(header: Text(category.name)) {
                    LazyVGrid(columns: adaptiveColumns, spacing: 10) {
                        ForEach(category.icons, id: \.self) { iconName in
                            iconButton(for: iconName, in: category)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .listSectionSeparator(.hidden)
                .listRowBackground(Color(UIColor.systemGroupedBackground))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    /// Color picker section at the bottom
    private var colorPickerSection: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: colorColumns, spacing: 12) {
                ForEach(colorManager.getAvailableColors().filter { $0 != .colorPicker }, id: \.self) { color in
                    colorButton(for: color)
                }
                
                customColorPicker
            }
        }
        .padding()
        .padding(.horizontal)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    /// Individual icon button
    private func iconButton(for iconName: String, in category: IconCategory) -> some View {
        Button {
            selectedIcon = iconName
        } label: {
            VStack {
                iconImage(for: iconName, isCustom: category.isCustom)
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        selectedIcon == iconName ? 
                            (selectedColor == .colorPicker ? customColor : selectedColor.color) :
                            Color.primary.opacity(0.1),
                        lineWidth: selectedIcon == iconName ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(iconAccessibilityLabel(for: iconName, isCustom: category.isCustom))
    }
    
    /// Icon image with proper sizing and styling
    private func iconImage(for iconName: String, isCustom: Bool) -> some View {
        Image(systemName: iconName)
            .font(.system(size: iconSize * 0.8, weight: .medium))
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(
                iconName == defaultIcon
                ? colorManager.selectedColor.color
                : (selectedColor == .colorPicker ? customColor : selectedColor.color)
            )
    }
    
    /// Individual color button
    private func colorButton(for color: HabitIconColor) -> some View {
        Button {
            selectedColor = color
        } label: {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(color.color)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .opacity(selectedColor == color ? 1 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(color.rawValue.localized) color")
    }
    
    /// Custom color picker
    private var customColorPicker: some View {
        ColorPicker("", selection: $customColor)
            .labelsHidden()
            .onChange(of: customColor) { _, newColor in
                HabitIconColor.customColor = newColor
                selectedColor = .colorPicker
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
            .accessibilityLabel("custom_color_picker".localized)
    }
    
    /// Accessibility label for icons
    private func iconAccessibilityLabel(for iconName: String, isCustom: Bool) -> String {
        return "\(iconName) icon"
    }
}

// MARK: - Icon Category Model

struct IconCategory {
    let name: String
    let icons: [String]
    let isCustom: Bool
    
    init(name: String, icons: [String], isCustom: Bool = false) {
        self.name = name
        self.icons = icons
        self.isCustom = isCustom
    }
}
