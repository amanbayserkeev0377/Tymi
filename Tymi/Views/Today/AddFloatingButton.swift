import SwiftUI

struct AddFloatingButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.black)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}

#Preview {
    VStack {
        AddFloatingButton(action: {})
            .preferredColorScheme(.light)
        
        AddFloatingButton(action: {})
            .preferredColorScheme(.dark)
    }
    .padding()
}
