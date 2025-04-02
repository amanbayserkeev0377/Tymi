import SwiftUI

struct DayCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    let viewModel: CalendarViewModel
    let onSelect: () -> Void
    
    private var day: Int {
        viewModel.day(for: date)
    }
    
    private var isToday: Bool {
        viewModel.isToday(date)
    }
    
    private var isSelected: Bool {
        viewModel.isSelected(date)
    }
    
    private var isCurrentMonth: Bool {
        viewModel.isCurrentMonth(date)
    }
    
    private var isFuture: Bool {
        viewModel.isFuture(date)
    }
    
    private var completionStatus: CompletionStatus {
        viewModel.completionStatus(for: date)
    }
    
    private var textColor: Color {
        if isSelected {
            return colorScheme == .dark ? .black : .white
        } else if isToday {
            return colorScheme == .dark ? .white : .black
        } else if isCurrentMonth {
            return isFuture ? 
                (colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)) :
                (colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
        } else {
            return colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)
        }
    }
    
    var body: some View {
        Button {
            if !isFuture {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: 0.2)) {
                    onSelect()
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(day)")
                    .font(.system(size: 18, weight: isToday ? .bold : .regular))
                    .foregroundStyle(textColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? 
                                (colorScheme == .dark ? .white : .black) :
                                Color.clear)
                            .shadow(color: isSelected ? 
                                (colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1)) :
                                .clear,
                                radius: 4, x: 0, y: 2)
                    )
                
                if completionStatus != .none {
                    Circle()
                        .fill(completionStatus == .completed ? Color.green : 
                             completionStatus == .partiallyCompleted ? Color.orange : 
                             Color.primary)
                        .frame(width: 5, height: 5)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }
}
