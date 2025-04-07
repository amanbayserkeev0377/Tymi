import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel: CalendarViewModel
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var habitStore: HabitStore
    @Binding var isPresented: Bool
    @Binding var selectedDate: Date
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>, habitStore: HabitStore) {
        _selectedDate = selectedDate
        _isPresented = isPresented
        _viewModel = StateObject(wrappedValue: CalendarViewModel(selectedDate: selectedDate.wrappedValue, habitStore: habitStore))
    }
    
    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        ModalView(isPresented: $isPresented, title: viewModel.monthTitle) {
            VStack(spacing: 0) {
                // Month Navigation
                HStack(spacing: 20) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.previousMonth()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.nextMonth()
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.body.weight(.medium))
                            .foregroundStyle(viewModel.isCurrentMonth(Date()) ? .secondary : .primary)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.isCurrentMonth(Date()))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
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
                .padding(.bottom, 12)
                
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
                .padding(.bottom, 24)
            }
            .frame(width: UIScreen.main.bounds.width - 48)
            .glassCard()
        }
    }
}
