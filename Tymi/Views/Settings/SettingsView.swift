import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("firstDayOfWeek") private var firstDayOfWeek: Int = Calendar.current.firstWeekday
    @AppStorage("useSystemTheme") private var useSystemTheme: Bool = true
    @AppStorage("darkMode") private var darkMode: Bool = false
    @State private var notificationsEnabled: Bool = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Секция календаря
                    calendarSection
                        .sectionCard()
                    
                    // Секция внешнего вида
                    appearanceSection
                        .sectionCard()
                    
                    // Секция информации
                    informationSection
                        .sectionCard()
                    
                    Spacer(minLength: 40)
                }
                .padding(.top)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.3)
                                )
                                .frame(width: 26, height: 26)
                            Image(systemName: "xmark")
                                .foregroundStyle(
                                    colorScheme == .dark ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
                                )
                                .font(.caption2)
                                .fontWeight(.black)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(useSystemTheme ? nil : (darkMode ? .dark : .light))
    }
    
    // MARK: - Подсекции
    
    private var calendarSection: some View {
        VStack(spacing: 12) {
            // Заголовок секции
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.primary)
                
                Text("Календарь")
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .frame(height: 37)
            
            Divider()
            
            // Первый день недели
            HStack {
                Text("Первый день недели")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Picker("", selection: $firstDayOfWeek) {
                    Text("Воскресенье").tag(1)
                    Text("Понедельник").tag(2)
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }
            .frame(height: 37)
            .padding(.leading, 28)
        }
    }
    
    private var appearanceSection: some View {
        VStack(spacing: 12) {
            // Заголовок секции
            HStack {
                Image(systemName: "paintbrush")
                    .foregroundStyle(.primary)
                
                Text("Внешний вид")
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .frame(height: 37)
            
            Divider()
            
            // Уведомления
            HStack {
                Image(systemName: "bell.badge")
                    .foregroundStyle(.primary)
                    .frame(width: 24)
                
                Text("Уведомления")
                
                Spacer()
                
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
                    .tint(colorScheme == .dark ? Color.white.opacity(0.7) : .black)
            }
            .frame(height: 37)
            
            // Системная тема
            HStack {
                Image(systemName: "paintpalette")
                    .foregroundStyle(.primary)
                    .frame(width: 24)
                
                Text("Использовать системную тему")
                
                Spacer()
                
                Toggle("", isOn: $useSystemTheme)
                    .labelsHidden()
                    .tint(colorScheme == .dark ? Color.white.opacity(0.7) : .black)
            }
            .frame(height: 37)
            
            // Темная тема (если не используется системная)
            if !useSystemTheme {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.primary)
                        .frame(width: 24)
                    
                    Text("Тёмная тема")
                    
                    Spacer()
                    
                    Toggle("", isOn: $darkMode)
                        .labelsHidden()
                        .tint(colorScheme == .dark ? Color.white.opacity(0.7) : .black)
                }
                .frame(height: 37)
            }
        }
    }
    
    private var informationSection: some View {
        VStack(spacing: 12) {
            // Заголовок секции
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.primary)
                
                Text("Информация")
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            .frame(height: 37)
            
            Divider()
            
            // О приложении
            HStack {
                Text("О приложении")
                
                Spacer()
                
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }
            .frame(height: 37)
            .padding(.leading, 28)
            
            // Оценить приложение
            Button {
                // Action to open App Store review
                if let url = URL(string: "itms-apps://apple.com/app/idYOUR_APP_ID?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text("Оценить приложение")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 37)
            .padding(.leading, 28)
            
            // Связаться с нами
            Button {
                // Action to open mail app
                if let url = URL(string: "mailto:your.email@example.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Text("Связаться с нами")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 37)
            .padding(.leading, 28)
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
