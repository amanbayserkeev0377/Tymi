import SwiftUI

struct IconCategory {
    let name: String
    let icons: [String]
}

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var tempSelectedIcon: String?
    
    init(selectedIcon: Binding<String?>) {
        self._selectedIcon = selectedIcon
        self._tempSelectedIcon = State(initialValue: selectedIcon.wrappedValue)
    }
    
    // Категории иконок из SF Symbols
    private let categories: [IconCategory] = [
        IconCategory(name: "icon_category_health".localized, icons: [
            "figure.walk","figure.run", "figure.stairs", "figure.strengthtraining.traditional", "figure.cooldown", 
            "figure.mind.and.body", "figure.pool.swim", "shoeprints.fill", "bicycle", "bed.double",
            "brain", "eye", "heart", "lungs", "waterbottle", 
            "pills", "testtube.2", "stethoscope", "carrot", "tree"
        ]),
        IconCategory(name: "icon_category_productivity".localized, icons: [
            "brain.head.profile", "clock", "hourglass", "pencil.and.list.clipboard", "pencil.and.scribble",
            "book", "graduationcap", "translate", "function", "chart.pie",
            "checklist", "calendar.badge.clock", "person.2.wave.2", "bubble.left.and.bubble.right", "globe.americas",
            "medal", "macbook", "keyboard", "lightbulb.max", "atom"
        ]),
        IconCategory(name: "icon_category_hobbies".localized, icons: [
            "camera", "play.rectangle", "headphones", "music.note", "film",
            "paintbrush.pointed", "paintpalette", "photo", "theatermasks", "puzzlepiece.extension",
            "pianokeys",  "guitars", "rectangle.pattern.checkered", "mountain.2", "drone",
            "playstation.logo", "xbox.logo", "formfitting.gamecontroller", "motorcycle", "scooter",
            "soccerball", "basketball", "volleyball", "tennisball", "tennis.racket"
        ]),
        IconCategory(name: "icon_category_lifestyle".localized, icons: [
            "shower", "bathtub", "sink", "hands.and.sparkles", "washer",
            "fork.knife", "frying.pan", "popcorn", "cup.and.heat.waves", "birthday.cake",
            "cart", "takeoutbag.and.cup.and.straw", "gift", "hanger", "stroller",
            "face.smiling", "envelope", "phone", "beach.umbrella", "pawprint",
            "creditcard", "banknote", "location", "hand.palm.facing", "steeringwheel.and.hands"
        ]),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(categories, id: \.name) { category in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.name)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .fontWeight(.medium)
                                .padding(.leading)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60, maximum: 80))], spacing: 15) {
                                ForEach(category.icons, id: \.self) { iconName in
                                    Button {
                                        tempSelectedIcon = iconName
                                    } label: {
                                        Image(systemName: iconName)
                                            .font(.title)
                                            .tint(.primary)
                                            .frame(width: 60, height: 60)
                                            .background(
                                                IconButtonBackground(isSelected: tempSelectedIcon == iconName)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("icon_picker_title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("icon_picker_remove_icon".localized) {
                        selectedIcon = nil
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        selectedIcon = tempSelectedIcon
                        dismiss()
                    }
                }
            }
            .tint(.primary)
        }
    }
}

struct IconButtonBackground: View {
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let fillColor: Color
        if isSelected {
            fillColor = Color.primary.opacity(0.2)
        } else {
            fillColor = colorScheme == .dark ? Color.black.opacity(0.1) : Color.white.opacity(0.9)
        }
        
        return RoundedRectangle(cornerRadius: 10)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                        lineWidth: 0.5
                    )
            )
            .shadow(radius: 1)
    }
}

// Расширение для проверки nil или пустой строки
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self == nil || self!.isEmpty
    }
} 
