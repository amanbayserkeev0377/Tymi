import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties
    let habit: Habit
    @State private var selectedDate: Date = .now
    @State private var isTimerRunning = false
    @State private var timerStartTime: Date?
    
    // Состояние для отображения диалогов ввода
    @State private var isTimePickerSheetPresented = false
    @State private var isCountAlertPresented = false
    @State private var countInputText = ""
    
    // Состояние для TimePicker
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var selectedSeconds = 0
    @State private var isTimePickerPopoverPresented = false
    @State private var hourglassRotation: Double = 0
    @State private var timePickerDate = Date()
    
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
    
    // Формат текущего прогресса с учетом типа привычки
    private var formattedProgress: String {
        if habit.type == .count {
            return "\(currentProgress)/\(habit.goal)"
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
            ScrollView {
                VStack(spacing: 24) {
                    Text("Goal: \(habit.formattedGoal)")
                        .font(.subheadline)
                        .padding(.top)
                    
                    Spacer(minLength: 20)
                    
                    // Основная область с прогресс-кольцом и кнопками +/-
                    HStack(spacing: 40) {
                        // Кнопка минус
                        Button(action: {
                            decrementProgress()
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 32))
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
                                .font(.system(size: 32))
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
                            Image(systemName: "hourglass.bottomhalf.filled")
                                .font(.system(size: 24))
                                .tint(.primary)
                        }
                        
                        // Кнопка таймера для привычек типа Time или ручного ввода для Count
                        Button(action: {
                            if habit.type == .time {
                                toggleTimer()
                            } else {
                                isCountAlertPresented = true
                            }
                        }) {
                            if habit.type == .time {
                                Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 44))
                                    .tint(.primary)
                            } else {
                                Image(systemName: "plus.arrow.trianglehead.clockwise")
                                    .font(.system(size: 24))
                                    .tint(.primary)
                            }
                        }
                        
                        // Ручной ввод для привычек типа Time
                        if habit.type == .time {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    hourglassRotation += 360
                                    isTimePickerPopoverPresented = true
                                }
                            }) {
                                Image(systemName: "hourglass.tophalf.filled")
                                    .font(.system(size: 24))
                                    .tint(.primary)
                                    .rotationEffect(.degrees(hourglassRotation))
                            }
                            .sheet(isPresented: $isTimePickerPopoverPresented) {
                                WheelPickerPopoverView(
                                    hours: $selectedHours,
                                    minutes: $selectedMinutes,
                                    isPresented: $isTimePickerPopoverPresented
                                ) { totalSeconds in
                                    currentProgress += totalSeconds
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        hourglassRotation += 360
                                    }
                                }
                                .presentationDetents([.height(200)])
                                .presentationBackground(.ultraThinMaterial)
                                .presentationCornerRadius(100)
                                .presentationDragIndicator(.visible)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                    
                    Spacer()
                    
                    // Кнопка завершения
                    Button(action: {
                        saveProgress()
                        dismiss()
                    }) {
                        Text("Complete")
                            .font(.headline)
                            .foregroundStyle(
                                colorScheme == .dark ? .black : .white
                            )
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
            .navigationTitle(habit.title)
            .navigationBarTitleDisplayMode(.inline)
            
            // Alert для привычки типа Count
            .alert("Enter value", isPresented: $isCountAlertPresented) {
                TextField("Value", text: $countInputText)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    countInputText = ""
                }
                Button("Add") {
                    if let value = Int(countInputText), value > 0 {
                        currentProgress += value
                    }
                    countInputText = ""
                }
            }
            .tint(.primary)
        }
        .onReceive(timer) { _ in
            updateTimerIfRunning()
        }
        .onDisappear {
            saveProgress()
        }
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
        
        // Обновляем отображаемое значение в реальном времени
        let elapsedTime = Int(Date().timeIntervalSince(startTime))
        // Используем временное значение только для отображения
        _ = currentProgress + elapsedTime
    }
}

// MARK: - WheelPickerPopoverView
struct WheelPickerPopoverView: View {
    @Binding var hours: Int
    @Binding var minutes: Int
    @Binding var isPresented: Bool
    let onSubmit: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Picker("", selection: $hours) {
                    ForEach(0...23, id: \.self) { hour in
                        Text("\(hour)").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 64)
                .clipped()
                .labelsHidden()
                
                Text(":")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)
                
                Picker("", selection: $minutes) {
                    ForEach(0...59, id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 64)
                .clipped()
                .labelsHidden()
            }
            
            Button("Done") {
                submitValue()
                isPresented = false
            }
            .tint(.primary)
            .padding(.top, 16)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
    }
    
    private func submitValue() {
        let totalSeconds = hours * 3600 + minutes * 60
        onSubmit(totalSeconds)
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
