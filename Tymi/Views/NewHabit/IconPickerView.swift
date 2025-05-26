import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Binding var selectedColor: HabitIconColor
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var colorManager = AppColorManager.shared
    
    // Дефолтная иконка
    private let defaultIcon = "checkmark"
    
    // Состояние для пользовательского цвета
    @State private var customColor = HabitIconColor.customColor
    
    private let categories: [IconCategory] = [
        IconCategory(name: "health".localized, icons: [
            "figure.walk","figure.run", "figure.stairs", "figure.strengthtraining.traditional", "figure.cooldown",
            "figure.mind.and.body", "figure.pool.swim", "shoeprints.fill", "bicycle", "bed.double",
            "brain", "eye", "heart", "lungs", "waterbottle",
            "pills", "testtube.2", "stethoscope", "carrot", "tree"
        ]),
        IconCategory(name: "productivity".localized, icons: [
            "brain.head.profile", "clock", "hourglass", "pencil.and.list.clipboard", "pencil.and.scribble",
            "book", "graduationcap", "translate", "function", "chart.pie",
            "checklist", "calendar.badge.clock", "person.2.wave.2", "bubble.left.and.bubble.right", "globe.americas",
            "medal", "macbook", "keyboard", "lightbulb.max", "atom"
        ]),
        IconCategory(name: "hobbies".localized, icons: [
            "camera", "play.rectangle", "headphones", "music.note", "film",
            "paintbrush.pointed", "paintpalette", "photo", "theatermasks", "puzzlepiece.extension",
            "pianokeys", "guitars", "rectangle.pattern.checkered", "mountain.2", "drone",
            "playstation.logo", "xbox.logo", "formfitting.gamecontroller", "motorcycle", "scooter",
            "soccerball", "basketball", "volleyball", "tennisball", "tennis.racket"
        ]),
        IconCategory(name: "lifestyle".localized, icons: [
            "shower", "bathtub", "sink", "hands.and.sparkles", "washer",
            "fork.knife", "frying.pan", "popcorn", "cup.and.heat.waves", "birthday.cake",
            "cart", "takeoutbag.and.cup.and.straw", "gift", "hanger", "stroller",
            "face.smiling", "envelope", "phone", "beach.umbrella", "pawprint",
            "creditcard", "banknote", "location", "hand.palm.facing", "steeringwheel.and.hands"
        ]),
        IconCategory(name: "pro".localized, icons: [
            "icon_instagram"
            // сюда будете добавлять новые Pro иконки
        ], isCustom: true)
    ]
    
    private let colorColumns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon selection list
            List {
                ForEach(categories, id: \.name) { category in // ИСПРАВЛЕНО: добавлен categories
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
                                        // Проверяем тип иконки
                                        if category.isCustom {
                                            Image(iconName) // Пользовательские иконки из Assets
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 30, height: 30)
                                                .foregroundStyle(selectedColor == .colorPicker ? customColor : selectedColor.color)
                                        } else {
                                            Image(systemName: iconName) // SF Symbols
                                                .font(.title)
                                                .foregroundStyle(iconName == defaultIcon ? colorManager.selectedColor.color : (selectedColor == .colorPicker ? customColor : selectedColor.color))
                                        }
                                    }
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.systemBackground))
                                            .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(selectedIcon == iconName ? 0.3 : 0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
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
            
            // Color selection section - теперь внизу
            VStack(spacing: 16) {
                // Color picker grid
                LazyVGrid(columns: colorColumns, spacing: 12) {
                    // Остальные цвета
                    ForEach(colorManager.getAvailableColors().filter { $0 != .colorPicker }, id: \.self) { color in
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
                    }
                    
                    ColorPicker("", selection: $customColor)
                        .labelsHidden()
                        .onChange(of: customColor) { _, newColor in
                            HabitIconColor.customColor = newColor
                            selectedColor = .colorPicker
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                }
            }
            .padding()
            .padding(.horizontal)
            .background(Color(UIColor.systemGroupedBackground))
        }
        .navigationTitle("choose_icon".localized)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedIcon == nil {
                selectedIcon = defaultIcon
            }
        }
    }
}

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
