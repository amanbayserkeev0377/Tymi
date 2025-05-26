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
            "soccerball.inverse", "basketball.fill", "volleyball.fill", "tennisball.fill", "tennis.racket"
        ]),
        IconCategory(name: "lifestyle".localized, icons: [
            "shower.fill", "bathtub.fill", "sink.fill", "hands.and.sparkles.fill", "washer.fill",
            "fork.knife", "frying.pan.fill", "popcorn.fill", "cup.and.heat.waves.fill", "birthday.cake.fill",
            "cart.fill", "takeoutbag.and.cup.and.straw.fill", "gift.fill", "hanger", "stroller.fill",
            "face.smiling.inverse", "envelope.fill", "phone.fill", "beach.umbrella.fill", "pawprint.fill",
            "creditcard.fill", "banknote.fill", "location.fill", "hand.palm.facing.fill", "steeringwheel.and.hands"
        ]),
        IconCategory(name: "pro".localized, icons: [
            "icon_instagram",
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
