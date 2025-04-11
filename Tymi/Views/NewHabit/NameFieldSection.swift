import SwiftUI

struct NameFieldSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var name: String
    
    var body: some View {
        HStack {
            Image(systemName: "pencil")
                .font(.body.weight(.medium))
                .foregroundStyle(colorScheme == .dark ? .white : .black)
                .frame(width: 28, height: 28)
            
            TextField("Habit Name", text: $name)
                .font(.body)
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            Section {
                NameFieldSection(name: .constant("Morning Workout"))
            }
        }
    }
} 