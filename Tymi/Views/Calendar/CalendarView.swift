import SwiftUI

struct CalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Временный заголовок месяца
                Text(formattedMonth())
                    .font(.title)
                    .fontWeight(.bold)
                
                // Простая сетка для дней (заглушка)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                    // Заголовки дней недели
                    ForEach(daysOfWeek(), id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Дни месяца (заглушка)
                    ForEach(1..<31) { day in
                        Button {
                            // Создаем дату из текущего дня
                            if let newDate = createDate(day: day) {
                                selectedDate = newDate
                                // Закрываем календарь после выбора даты
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            }
                        } label: {
                            Text("\(day)")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    isCurrentDay(day: day)
                                    ? Circle().fill(Color.green)
                                    : Circle().fill(Color.clear)
                                )
                                .foregroundStyle(
                                    isCurrentDay(day: day) ? .white : .primary
                                )
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Кнопка "Сегодня"
                Button {
                    selectedDate = Date()
                    dismiss()
                } label: {
                    Text("Сегодня")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Вспомогательные функции
    
    // Возвращает отформатированное название месяца
    private func formattedMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    // Возвращает дни недели
    private func daysOfWeek() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    // Проверяет, соответствует ли день текущей выбранной дате
    private func isCurrentDay(day: Int) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.day, from: selectedDate) == day
    }
    
    // Создает новую дату на основе дня и текущего месяца/года
    private func createDate(day: Int) -> Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        var newComponents = DateComponents()
        newComponents.year = components.year
        newComponents.month = components.month
        newComponents.day = day
        return calendar.date(from: newComponents)
    }
}

#Preview {
    CalendarView(selectedDate: .constant(Date()))
}
