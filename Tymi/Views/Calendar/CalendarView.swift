import SwiftUI

struct CalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var habitStore: HabitStoreManager
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Calendar placeholder")
                    .font(.title)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView(isPresented: .constant(true))
        .environmentObject(HabitStoreManager())
}
