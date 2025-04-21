import SwiftUI
import SwiftData

struct TodayView: View {
    //MARK: - Properties
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    @Query(filter: #Predicate<Habit> { !$0.isArchived },
           sort: \Habit.createdAt)
    private var habits: [Habit]
    
    @State private var selectedDate: Date = .now
    @State private var isShowingNewHabitSheet = false
    @State private var selectedHabit: Habit? = nil
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                TodayViewBackground()
                
                VStack(spacing: 0) {
                    if habits.isEmpty {
                        EmptyStateView()
                    } else {
                        habitsList
                    }
                }
            }
            
            // AddFloatingButton
            .overlay(alignment: .bottomTrailing) {
                AddFloatingButton(action: { isShowingNewHabitSheet = true })
            }
            .navigationTitle(formattedNavigationTitle(for: selectedDate))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        // Open settings
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .tint(.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Open calendar
                    }) {
                        Image(systemName: "calendar")
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $isShowingNewHabitSheet) {
                NewHabitView()
                    .presentationBackground {
                        ZStack {
                            Rectangle().fill(.ultraThinMaterial)
                            if colorScheme != .dark {
                                Color.white.opacity(0.7)
                            }
                        }
                    }
            }
            
            .sheet(item: $selectedHabit) { habit in
                HabitDetailView(habit: habit, date: selectedDate)
                    .presentationDetents([.fraction(0.7)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(40)
                    .presentationBackground {
                        let cornerRadius: CGFloat = 40
                        ZStack {
                            // Основной фон с размытием
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.ultraThinMaterial)
                            
                            if colorScheme == .dark {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                                    .blur(radius: 0.5)
                                
                                RoundedRectangle(cornerRadius: cornerRadius - 1)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            } else {
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .fill(Color.white.opacity(0.4))
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                                    .blur(radius: 0.5)
                                    .offset(y: -0.5)
                                
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 2)
                                    .blur(radius: 1)
                                    .offset(y: 1)
                            }
                        }
                    }
            }
            
        }
    }
    
    // MARK: - Subviews
    
    private var habitsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(habits) { habit in
                    if habit.isActiveOnDate(selectedDate) {
                        HabitRowView(
                            habit: habit,
                            date: selectedDate,
                            onTap: {
                                selectedHabit = habit
                            }
                        )
                    }
                }
                
                Spacer(minLength: 80)
            }
            .padding(.top, 12)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    private func isYesterday(_ date: Date) -> Bool {
        return Calendar.current.isDateInYesterday(date)
    }
    
    private func formattedNavigationTitle(for date: Date) -> String {
        if isToday(date) {
            return "Today"
        } else if isYesterday(date) {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: date)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
