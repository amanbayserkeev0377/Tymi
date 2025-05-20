import SwiftUI

struct AppIconPickerView: View {
    @ObservedObject private var iconManager = AppIconManager.shared
    
    var body: some View {
        List {
            ForEach(AppIcon.allIcons, id: \.id) { icon in
                Button {
                    iconManager.setAppIcon(icon)
                } label: {
                    HStack {
                        Image(icon.preview)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                            .padding(.trailing, 8)
                        
                        Text(icon.displayName)
                            .font(.headline)
                        
                        Spacer()
                        
                        if iconManager.currentIcon.id == icon.id {
                            Image(systemName: "checkmark")
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("choose_icon".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
