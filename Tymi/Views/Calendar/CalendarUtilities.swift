import Foundation

// Расширение для Calendar для добавления общих функций
extension Calendar {
    // Получение первого дня месяца
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    // Получение последнего дня месяца
    func endOfMonth(for date: Date) -> Date {
        guard let startOfMonth = self.date(from: dateComponents([.year, .month], from: date)) else {
            return date
        }
        
        guard let range = range(of: .day, in: .month, for: date),
              let lastDay = self.date(byAdding: .day, value: range.count - 1, to: startOfMonth) else {
            return date
        }
        
        return lastDay
    }
    
    // Проверка, является ли дата сегодняшним днем
    func isToday(_ date: Date) -> Bool {
        return isDate(date, inSameDayAs: Date())
    }
}
