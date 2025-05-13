import SwiftUI
import SwiftData


// заглушка
struct HabitStatisticsView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Заголовок и основная информация
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(habit.formattedGoal)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Иконка привычки, если есть
                    if let iconName = habit.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 36))
                            .frame(width: 60, height: 60)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom)
                
                // Секция с общей статистикой
                Section {
                    Text("Общая статистика")
                        .font(.headline)
                        .padding(.vertical, 8)
                    
                    // Содержимое секции (заглушка)
                    VStack(alignment: .leading, spacing: 12) {
                        StatRow(title: "Выполнено раз", value: "42")
                        StatRow(title: "Текущая серия", value: "5 дней")
                        StatRow(title: "Лучшая серия", value: "12 дней")
                        StatRow(title: "Процент выполнения", value: "87%")
                    }
                    .padding()
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Секция с графиками (заглушка)
                Section {
                    Text("Динамика выполнения")
                        .font(.headline)
                        .padding(.vertical, 8)
                    
                    // Заглушка для графика
                    VStack {
                        Text("Здесь будет располагаться график выполнения привычки")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Секция с детализацией
                Section {
                    Text("Детализация по дням")
                        .font(.headline)
                        .padding(.vertical, 8)
                    
                    // Заглушка для списка дней
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(0..<7) { i in
                            DayStatRow(
                                day: Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date(),
                                isCompleted: Bool.random(),
                                value: Int.random(in: 0...100)
                            )
                            if i < 6 {
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Статистика")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
    }
}

// Вспомогательные компоненты
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

struct DayStatRow: View {
    let day: Date
    let isCompleted: Bool
    let value: Int
    
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE, d MMM"
        return formatter
    }()
    
    var body: some View {
        HStack {
            Text(dateFormatter.string(from: day))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(isCompleted ? .green : .red)
                
                Text(String(value))
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}
