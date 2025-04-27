import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDate: Date
    
    private let currentDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("",
                    selection: $selectedDate,
                    in: ...currentDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(.primary)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.3)
                                )
                                .frame(width: 26, height: 26)
                            Image(systemName: "xmark")
                                .foregroundStyle(
                                    colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
                                )
                                .font(.caption2)
                                .fontWeight(.black)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView(selectedDate: .constant(Date()))
        .preferredColorScheme(.dark)
} 
