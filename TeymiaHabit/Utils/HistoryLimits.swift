import Foundation

/// Централизованные ограничения для истории привычек
enum HistoryLimits {
    /// Максимальная история привычек в годах
    /// Используется во всех графиках, календарях и при создании привычек
    static let maxYears = 5
    
    /// Вычисляет самую раннюю дату, которую можно показывать в приложении
    static func earliestAllowedDate() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .year, value: -maxYears, to: Date()) ?? Date()
    }
    
    /// Применяет ограничение к дате начала привычки для отображения
    /// - Parameter startDate: Исходная дата начала привычки
    /// - Returns: Дата с учетом ограничения (не раньше чем maxYears назад)
    static func limitStartDate(_ startDate: Date) -> Date {
        return max(startDate, earliestAllowedDate())
    }
    
    /// Диапазон дат для DatePicker при создании/редактировании привычки
    static var datePickerRange: ClosedRange<Date> {
        return earliestAllowedDate()...Date()
    }
}
