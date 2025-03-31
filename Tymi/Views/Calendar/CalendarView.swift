import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var habitStore: HabitStore
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: CalendarViewModel(selectedDate: selectedDate.wrappedValue))
        _selectedDate = selectedDate
        _isPresented = isPresented
    }
    
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with month and navigation
            HStack {
                Text(viewModel.monthTitle)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.previousMonth()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.nextMonth()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(viewModel.isCurrentMonth(Date()) ? 
                                (colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)) :
                                (colorScheme == .dark ? .white : .black))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(viewModel.isCurrentMonth(Date()))
                }
            }
            .padding(.horizontal, 24)
            
            // Weekday headers
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(viewModel.dates, id: \.self) { date in
                    DayCell(date: date, viewModel: viewModel) {
                        if !viewModel.isFuture(date) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                                isPresented = false
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
}
