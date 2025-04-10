import SwiftUI

struct NameFieldSection: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var name: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "pencil")
                    .font(.body.weight(.medium))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                    .frame(width: 28, height: 28)
                
                TextField("Habit Name", text: $name)
                    .font(.title3.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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