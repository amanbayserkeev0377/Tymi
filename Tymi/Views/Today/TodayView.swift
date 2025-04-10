import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel: TodayViewModel
    @EnvironmentObject private var habitStore: HabitStoreManager
    @State private var showingNewHabit = false
    @State private var showingSettings = false
    @State private var selectedHabit: Habit?
    @State private var editingHabit: Habit?
    @Namespace private var namespace
    
    // Haptic feedback
    private let feedback = UIImpactFeedbackGenerator(style: .light)
    
    init(habitStore: HabitStoreManager = HabitStoreManager()) {
        self._viewModel = StateObject(wrappedValue: TodayViewModel(habitStore: habitStore))
    }
    
    private var habitsForSelectedDate: [Habit] {
        habitStore.habits.filter { habit in
            let weekday = Calendar.current.component(.weekday, from: viewModel.selectedDate)
            return habit.activeDays.contains(weekday)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date carousel
                DateCarouselView(
                    selectedDate: viewModel.selectedDate,
                    onDateSelected: { date in
                        feedback.impactOccurred()
                        viewModel.selectDate(date)
                    },
                    namespace: namespace
                )
                .frame(height: 120)
                
                Divider()
                
                // Content
                ScrollView {
                    if habitsForSelectedDate.isEmpty {
                        EmptyStateView()
                            .padding(.top, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(habitsForSelectedDate) { habit in
                                Button {
                                    selectedHabit = habit
                                } label: {
                                    HabitRowView(habit: habit)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(viewModel.formattedFullDate())
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewHabit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewHabit) {
                NavigationStack {
                    NewHabitView(
                        habitStore: habitStore,
                        habit: editingHabit,
                        isPresented: $showingNewHabit,
                        onSave: { habit in
                            if editingHabit != nil {
                                habitStore.updateHabit(habit)
                            } else {
                                habitStore.addHabit(habit)
                            }
                            editingHabit = nil
                        }
                    )
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(isPresented: $showingSettings)
                }
            }
            .sheet(item: $selectedHabit) { habit in
                NavigationStack {
                    HabitDetailView(
                        habit: habit,
                        habitStore: habitStore,
                        isPresented: Binding(
                            get: { selectedHabit != nil },
                            set: { if !$0 { selectedHabit = nil } }
                        ),
                        onEdit: { habit in
                            editingHabit = habit
                            selectedHabit = nil
                            showingNewHabit = true
                        },
                        onDelete: { habit in
                            habitStore.deleteHabit(habit)
                            selectedHabit = nil
                        }
                    )
                }
            }
        }
    }
}

struct DateCarouselView: View {
    let selectedDate: Date
    let onDateSelected: (Date) -> Void
    let namespace: Namespace.ID
    
    private let calendar = Calendar.current
    private let dateRange = -14..<1 // 2 недели назад до сегодня
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(dateRange, id: \.self) { dayOffset in
                        let date = calendar.date(byAdding: .day, value: dayOffset, to: Date())!
                        DateCardView(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            namespace: namespace,
                            onTap: { onDateSelected(date) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct DateCardView: View {
    let date: Date
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .global).minX
            let rotation = Double(minX - 20) / -20
            let scale = max(0.85, min(1, 1 - abs(Double(minX - 20) / 800)))
            
            VStack(spacing: 8) {
                Text(dayOfWeek())
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(dayNumber())
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                
                if isSelected {
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(.white)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(width: 80, height: 100)
            .background(
                ZStack {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.plusLighter)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),
                perspective: 1
            )
            .scaleEffect(isSelected ? 1.08 : scale)
            .animation(.easeInOut(duration: 0.3), value: minX)
            .animation(.spring(), value: isSelected)
            .matchedGeometryEffect(id: "date_\(date.hashValue)", in: namespace)
            .onTapGesture(perform: onTap)
        }
        .frame(width: 80, height: 100)
    }
    
    private var gradientColors: [Color] {
        if isSelected {
            return [.blue, .purple]
        } else if isToday {
            return [.orange, .pink]
        } else {
            return [.gray.opacity(0.5), .black.opacity(0.5)]
        }
    }
    
    private func dayOfWeek() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date).uppercased()
    }
    
    private func dayNumber() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - EmptyStateView
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No habits for today")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Add a new habit to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

#Preview {
    TodayView()
        .environmentObject(HabitStoreManager())
}

