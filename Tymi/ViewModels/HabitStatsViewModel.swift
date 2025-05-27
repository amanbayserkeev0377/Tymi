import SwiftUI
import SwiftData

@Observable
class HabitStatsViewModel {
    let habit: Habit
    
    // Основные метрики, которые мы отслеживаем
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var totalValue: Int = 0
    
    // Убираем updateCounter - он нам больше не нужен
    
    init(habit: Habit) {
        self.habit = habit
        calculateStats()
    }
    
    // MARK: - Public Methods
    
    /// Обновляет статистику без пересоздания ViewModel
    func refresh() {
        calculateStats()
    }
    
    // MARK: - Private Methods
    
    func calculateStats() {
        let calendar = Calendar.current
        
        // Получаем все даты завершения
        var completedDates: [Date] = []
        var completedDaysSet = Set<Date>()
        
        guard let completions = habit.completions else {
            // Сбрасываем значения если нет завершений
            currentStreak = 0
            bestStreak = 0
            totalValue = 0
            return
        }
        
        // Собираем данные о завершениях
        for completion in completions {
            let dayStart = calendar.startOfDay(for: completion.date)
            
            // Отслеживание завершенных дней
            if completion.value >= habit.goal {
                if !completedDates.contains(where: { calendar.isDate($0, inSameDayAs: dayStart) }) {
                    completedDates.append(dayStart)
                }
                completedDaysSet.insert(dayStart)
            }
        }
        
        // Обновляем значения
        totalValue = completedDaysSet.count
        currentStreak = calculateCurrentStreak(completedDates: completedDates)
        bestStreak = calculateBestStreak(completedDates: completedDates)
    }
    
    // Вычисление текущей серии
    private func calculateCurrentStreak(completedDates: [Date]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Преобразуем даты в начало дня и сортируем по убыванию
        let sortedDates = completedDates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
        
        // Если нет выполненных дат, возвращаем 0
        guard !sortedDates.isEmpty else { return 0 }
        
        // Проверяем, выполнена ли привычка сегодня
        let isCompletedToday = sortedDates.contains { calendar.isDate($0, inSameDayAs: today) }
        
        // Если сегодня активный день для привычки и привычка не выполнена
        // (и время позднее, например, 23:00), стрик прерывается
        if habit.isActiveOnDate(today) && !isCompletedToday && calendar.component(.hour, from: Date()) >= 23 {
            return 0
        }
        
        // Считаем стрик с последней выполненной даты
        var streak = 0
        var currentDate = isCompletedToday ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Двигаемся назад по дням и проверяем выполнения
        while true {
            // Если день не активен, пропускаем его
            if !habit.isActiveOnDate(currentDate) {
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                // Прекращаем если вышли за пределы начальной даты
                if currentDate < habit.startDate {
                    break
                }
                continue
            }
            
            // Проверяем, выполнена ли привычка в этот день
            let isCompletedOnDate = sortedDates.contains { calendar.isDate($0, inSameDayAs: currentDate) }
            
            if isCompletedOnDate {
                // Увеличиваем счетчик стрика
                streak += 1
                // Двигаемся к предыдущему дню
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                
                // Прекращаем если вышли за пределы начальной даты
                if currentDate < habit.startDate {
                    break
                }
            } else {
                // Стрик прерван при первом невыполненном активном дне
                break
            }
        }
        
        return streak
    }
    
    // Вычисление лучшей серии
    private func calculateBestStreak(completedDates: [Date]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Преобразуем даты в начало дня
        let completedDays = completedDates
            .map { calendar.startOfDay(for: $0) }
            .reduce(into: Set<Date>()) { result, date in
                result.insert(date)
            }
        
        var bestStreak = 0
        var currentStreak = 0
        var checkDate = calendar.startOfDay(for: habit.startDate)
        
        // Проходим все дни от начала привычки до сегодня
        while checkDate <= today {
            // Если день активен для привычки
            if habit.isActiveOnDate(checkDate) {
                // Проверяем, выполнена ли привычка в этот день
                if completedDays.contains(checkDate) {
                    currentStreak += 1
                    // Обновляем лучший стрик, если текущий больше
                    bestStreak = max(bestStreak, currentStreak)
                } else {
                    // Стрик прерван
                    currentStreak = 0
                }
            }
            
            // Переходим к следующему дню
            checkDate = calendar.date(byAdding: .day, value: 1, to: checkDate)!
        }
        
        return bestStreak
    }
}
