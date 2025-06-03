import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<Habit> { habit in
            !habit.isArchived
        },
        sort: [SortDescriptor(\Habit.createdAt)]
    )
    private var allHabits: [Habit]
    
    // Computed property для правильной сортировки с isPinned
    private var habits: [Habit] {
        allHabits.sorted { first, second in
            // Сначала сортируем по isPinned (pinned наверху)
            if first.isPinned != second.isPinned {
                return first.isPinned && !second.isPinned
            }
            // Потом по дате создания
            return first.createdAt < second.createdAt
        }
    }
    
    @State private var selectedHabitForStats: Habit? = nil
    
    var body: some View {
        NavigationStack {
            if habits.isEmpty {
                StatisticsEmptyStateView()
            } else {
                List {
                    Section {
                        ForEach(habits) { habit in
                            Button {
                                selectedHabitForStats = habit
                            } label: {
                                HStack {
                                    if let iconName = habit.iconName {
                                        Image(systemName: iconName)
                                            .font(.system(size: 24))
                                            .frame(width: 24, height: 24)
                                            .foregroundStyle(habit.iconName == nil ? AppColorManager.shared.selectedColor.color : habit.iconColor.color)
                                    }
                                    
                                    Text(habit.title)
                                        .tint(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Color(uiColor: .systemGray3))
                                        .font(.footnote)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(habits.isEmpty ? "" : "statistics".localized) // Убираем title когда пусто
        .navigationBarTitleDisplayMode(habits.isEmpty ? .inline : .large) // inline когда пусто
        .sheet(item: $selectedHabitForStats) { habit in
            NavigationStack {
                HabitStatisticsView(habit: habit)
            }
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Statistics Empty State

struct StatisticsEmptyStateView: View {
    @State private var isAnimating = false
    @ObservedObject private var colorManager = AppColorManager.shared
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "chart.line.text.clipboard")
                .font(.system(size: 120, weight: .thin))
                .foregroundStyle(colorManager.selectedColor.color.opacity(0.3))
                .scaleEffect(isAnimating ? 1.05 : 0.98)
                .animation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}
