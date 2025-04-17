import SwiftUI

struct AddFloatingButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.black)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}
