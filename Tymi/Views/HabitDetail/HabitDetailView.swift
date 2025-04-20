import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    @State private var selectedDate: Date = .now
    @State private var isShowingActionSheet = false
    @State private var isShowingManualInput = false
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    
    // Состояние для ввода значения
    @State private var inputValue: String = ""
    @State private var isInputFocused: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Временный прогресс для экрана (будет сохранен при закрытии)
    @State private var currentProgress: Int
    
    // Для отслеживания таймера в реальном времени
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Инициализация
    init(habit: Habit, date: Date = .now) {
        self.habit = habit
        self.selectedDate = date
        // Инициализируем текущий прогресс из привычки
        self._currentProgress = State(initialValue: habit.progressForDate(date))
    }
    
    // MARK: - Computed Properties
    // Процент выполнения
    private var completionPercentage: Double {
        guard habit.goal > 0 else { return 0 }
        return min(Double(currentProgress) / Double(habit.goal), 1.0)
    }
    
    // Форматированный текущий прогресс
    private var formattedProgress: String {
        if habit.type == .count {
            return "\(currentProgress)"
        } else {
            // Форматирование для времени (часы:минуты:секунды)
            let hours = currentProgress / 3600
            let minutes = (currentProgress % 3600) / 60
            let seconds = currentProgress % 60
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 24) {
                    // Заголовок привычки
                    Text(habit.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Goal: \(habit.formattedGoal)")
                        .font(.subheadline)
                        .tint(.primary)
                    
                    Spacer(minLength: 20)
                    
                    // Основная область с прогресс-кольцом и кнопками +/-
                    HStack(spacing: 40) {
                        // Кнопка минус
                        Button(action: {
                            decrementProgress()
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 34))
                                .tint(.primary)
                        }
                        
                        // Прогресс-кольцо
                        ProgressRing(
                            progress: completionPercentage,
                            currentValue: formattedProgress
                        )
                        
                        // Кнопка плюс
                        Button(action: {
                            incrementProgress()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 34))
                                .tint(.primary)
                        }
                    }
                    .padding()
                    
                    Spacer(minLength: 20)
                    
                    // Кнопки дополнительных действий
                    HStack(spacing: 32) {
                        // Сброс значения
                        Button(action: {
                            resetProgress()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24))
                                .tint(.primary)
                        }
                        
                        // Кнопка таймера для привычек типа Time или ручного ввода для Count
                        Button(action: {
                            if habit.type == .time {
                                toggleTimer()
                            } else {
                                isInputFocused = true
                            }
                        }) {
                            if habit.type == .time {
                                Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 44))
                                    .tint(.primary)
                            } else {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 24))
                                    .tint(.primary)
                            }
                        }
                        
                        // Ручной ввод для привычек типа Time
                        if habit.type == .time {
                            Button(action: {
                                isInputFocused = true
                            }) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 24))
                                    .tint(.primary)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                    
                    // Кнопка Complete
                    Button(action: {
                        // TODO: Implement completion action
                        dismiss()
                    }) {
                        Text("Complete")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .padding()
            }
            .animation(.default, value: isInputFocused)
        }
        .overlay {
            if isInputFocused {
                InputOverlay(
                    habitType: habit.type,
                    isInputFocused: $isInputFocused,
                    inputValue: $inputValue
                ) { value in
                    currentProgress += value
                }
                .animation(.easeInOut, value: isInputFocused)
            }
        }
        .onReceive(timer) { _ in
            updateTimerIfRunning()
        }
        .onDisappear {
            saveProgress()
        }
        .presentationDetents([.fraction(0.7)])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Methods
    private func saveProgress() {
        // Проверяем, изменился ли прогресс
        let existingProgress = habit.progressForDate(selectedDate)
        if currentProgress != existingProgress {
            // Добавляем новую запись о прогрессе (разница)
            habit.addProgress(currentProgress - existingProgress, for: selectedDate)
        }
    }
    
    private func incrementProgress() {
        if habit.type == .count {
            currentProgress += 1
        } else {
            // Для времени +1 минута
            currentProgress += 60
        }
    }
    
    private func decrementProgress() {
        if habit.type == .count {
            if currentProgress > 0 {
                currentProgress -= 1
            }
        } else {
            // Для времени -1 минута (но не меньше 0)
            if currentProgress >= 60 {
                currentProgress -= 60
            } else {
                currentProgress = 0
            }
        }
    }
    
    private func resetProgress() {
        currentProgress = 0
        if isTimerRunning {
            isTimerRunning = false
            timerStartTime = nil
        }
    }
    
    private func toggleTimer() {
        if isTimerRunning {
            // Останавливаем таймер
            isTimerRunning = false
            
            // Если таймер был запущен, фиксируем прошедшее время
            if let startTime = timerStartTime {
                let elapsedTime = Int(Date().timeIntervalSince(startTime))
                currentProgress += elapsedTime
                timerStartTime = nil
            }
        } else {
            // Запускаем таймер
            isTimerRunning = true
            timerStartTime = Date()
        }
    }
    
    private func updateTimerIfRunning() {
        guard isTimerRunning, let startTime = timerStartTime, habit.type == .time else { return }
        
        // Обновляем отображаемое значение, но не сохраняем в currentProgress
        let elapsedTime = Int(Date().timeIntervalSince(startTime))
        // Это только для отображения, не изменяет реальное значение currentProgress
        _ = currentProgress + elapsedTime
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, HabitCompletion.self, configurations: config)
    
    // Создаем тестовую привычку типа Count
    let countHabit = Habit(title: "Отжимания", type: .count, goal: 50)
    
    // Создаем тестовую привычку типа Time
    let timeHabit = Habit(title: "Медитация", type: .time, goal: 3600) // 1 час
    
    return NavigationStack {
        TabView {
            HabitDetailView(habit: countHabit)
                .tabItem {
                    Label("Count", systemImage: "number")
                }
            
            HabitDetailView(habit: timeHabit)
                .tabItem {
                    Label("Time", systemImage: "timer")
                }
        }
    }
}
