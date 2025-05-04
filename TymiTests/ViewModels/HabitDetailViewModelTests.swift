import XCTest
import SwiftData
@testable import Tymi

final class HabitDetailViewModelTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var habit: Habit!
    var habitsUpdateService: HabitsUpdateService!
    
    override func setUpWithError() throws {
        // Create in-memory ModelContainer for tests
        let schema = Schema([Habit.self, HabitCompletion.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
        
        // Create dependencies
        habitsUpdateService = HabitsUpdateService()
    }
    
    override func tearDownWithError() throws {
        // Очищаем все таймеры между тестами
        if let habit = habit {
            HabitTimerService.shared.resetTimer(for: habit.id)
        }
    }
    
    // Вспомогательная функция для создания ViewModel
    func createViewModel(habitTitle: String = "Test Habit", type: HabitType = .count, goal: Int = 5) async -> (HabitDetailViewModel, Habit) {
        // Создаем новую привычку каждый раз, чтобы избежать перекрестных эффектов между тестами
        let habit = Habit(title: habitTitle, type: type, goal: goal)
        modelContext.insert(habit)
        self.habit = habit
        
        // Сбрасываем таймер для новой привычки
        HabitTimerService.shared.resetTimer(for: habit.id)
        
        // Создаем ViewModel
        let viewModel = await HabitDetailViewModel(
            habit: habit,
            date: Date(),
            modelContext: modelContext,
            habitsUpdateService: habitsUpdateService
        )
        
        return (viewModel, habit)
    }
    
    func testIncrementProgress() async throws {
        let (viewModel, _) = await createViewModel()
        
        // Проверяем начальное состояние
        let initialProgress = await viewModel.currentProgress
        XCTAssertEqual(initialProgress, 0)
        
        // Увеличиваем прогресс на 1
        await viewModel.incrementProgress()
        
        // Небольшая задержка, чтобы состояние успело обновиться
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 секунда
        
        let progress1 = await viewModel.currentProgress
        XCTAssertEqual(progress1, 1)
        
        // Увеличиваем еще 4 раза до цели
        for _ in 0..<4 {
            await viewModel.incrementProgress()
            // Короткая задержка между инкрементами
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        
        // Небольшая задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let finalProgress = await viewModel.currentProgress
        XCTAssertEqual(finalProgress, 5)
        
        let isCompleted = await viewModel.isAlreadyCompleted
        XCTAssertTrue(isCompleted)
    }
    
    func testDecrementProgress() async throws {
        let (viewModel, _) = await createViewModel()
        
        // Добавляем начальный прогресс
        await viewModel.incrementProgress()
        await viewModel.incrementProgress()
        
        // Задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let initialProgress = await viewModel.currentProgress
        XCTAssertEqual(initialProgress, 2)
        
        // Уменьшаем прогресс
        await viewModel.decrementProgress()
        
        // Задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let progress1 = await viewModel.currentProgress
        XCTAssertEqual(progress1, 1)
        
        // Дальнейшее уменьшение не должно сделать прогресс отрицательным
        await viewModel.decrementProgress()
        await viewModel.decrementProgress()
        
        // Задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let finalProgress = await viewModel.currentProgress
        XCTAssertEqual(finalProgress, 0)
    }
    
    func testCompleteHabit() async throws {
        let (viewModel, habit) = await createViewModel()
        
        // Начальное состояние
        let initialProgress = await viewModel.currentProgress
        XCTAssertEqual(initialProgress, 0)
        
        // Выполняем привычку
        await viewModel.completeHabit()
        
        // Задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Прогресс должен быть равен цели
        let finalProgress = await viewModel.currentProgress
        XCTAssertEqual(finalProgress, habit.goal)
        
        let isCompleted = await viewModel.isAlreadyCompleted
        XCTAssertTrue(isCompleted)
    }
    
    func testSaveProgress() async throws {
        let (viewModel, habit) = await createViewModel()
        
        // Добавляем прогресс
        await viewModel.incrementProgress()
        await viewModel.incrementProgress()
        
        // Задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Сохраняем прогресс
        await viewModel.saveProgress()
        
        // Задержка для сохранения в контексте
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Проверяем, что запись о выполнении создана
        XCTAssertGreaterThanOrEqual(habit.completions.count, 1)
        XCTAssertEqual(habit.progressForDate(Date()), 2)
    }
    
    func testTimeHabitFunctionality() async throws {
        // Тестируем привычку с типом "время"
        let (viewModel, _) = await createViewModel(type: .time, goal: 300) // 5 минут
        
        // Проверяем начальное состояние таймера
        let initialRunningState = await viewModel.isTimerRunning
        XCTAssertFalse(initialRunningState)
        
        // Запускаем таймер
        await viewModel.toggleTimer()
        
        // Задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let runningState = await viewModel.isTimerRunning
        XCTAssertTrue(runningState)
        
        // Ждем, чтобы таймер накопил прогресс
        try await Task.sleep(nanoseconds: 2_100_000_000) // 2.1 секунды
        
        // Проверяем прогресс
        let progress = await viewModel.currentProgress
        XCTAssertGreaterThanOrEqual(progress, 2)
        
        // Останавливаем таймер
        await viewModel.toggleTimer()
        
        // Задержка для обновления состояния
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let finalRunningState = await viewModel.isTimerRunning
        XCTAssertFalse(finalRunningState)
    }
}
