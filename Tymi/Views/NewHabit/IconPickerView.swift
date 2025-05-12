import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
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
            "pianokeys", "guitars", "rectangle.pattern.checkered", "mountain.2", "drone",
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
    
    private var filteredCategories: [IconCategory] {
        if searchText.isEmpty {
            return categories
        } else {
            return categories.map { category in
                IconCategory(
                    name: category.name,
                    icons: category.icons.filter { $0.contains(searchText.lowercased()) }
                )
            }.filter { !$0.icons.isEmpty }
        }
    }
    
    var body: some View {
        List {
            // Опция "Без иконки"
            Button {
                selectedIcon = nil
                dismiss()
            } label: {
                HStack {
                    Label("no_icon".localized, systemImage: "circle.slash")
                    Spacer()
                    if selectedIcon == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            ForEach(filteredCategories, id: \.name) { category in
                if !category.icons.isEmpty {
                    Section(header: Text(category.name)) {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 60))
                        ], spacing: 10) {
                            ForEach(category.icons, id: \.self) { iconName in
                                Button {
                                    selectedIcon = iconName
                                    dismiss()
                                } label: {
                                    VStack {
                                        Image(systemName: iconName)
                                            .font(.title)
                                            .frame(height: 44)
                                            .foregroundStyle(.primary)
                                        
                                        if selectedIcon == iconName {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    .frame(minWidth: 60, minHeight: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.primary.opacity(selectedIcon == iconName ? 0.1 : 0.0))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .navigationTitle("choose_icon".localized)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "search_icons".localized)
    }
}

struct IconCategory {
    let name: String
    let icons: [String]
}

// СТРОКИ ДЛЯ ЛОКАЛИЗАЦИИ:
/*
"icon" = "Иконка";
"choose_icon" = "Выберите иконку";
"no_icon" = "Без иконки";
"search_icons" = "Поиск иконок";
"icon_category_health" = "Здоровье";
"icon_category_productivity" = "Продуктивность";
"icon_category_hobbies" = "Хобби";
"icon_category_lifestyle" = "Стиль жизни";
*/
