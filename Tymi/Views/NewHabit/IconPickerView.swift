import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String?
    @Environment(\.dismiss) private var dismiss
    
    // SF Symbols
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
    ]
    
    var body: some View {
        List {
            Button {
                selectedIcon = nil
                dismiss()
            } label: {
                HStack {
                    Label("no_icon".localized, systemImage: "square.slash")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if selectedIcon == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            ForEach(categories, id: \.name) { category in
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
                                        .foregroundStyle(.primary)
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .padding(8)
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
        .navigationTitle("choose_icon".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IconCategory {
    let name: String
    let icons: [String]
}
