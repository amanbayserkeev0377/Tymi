import SwiftUI

struct GoalSectionContent: View {
    @Binding var selectedType: HabitType
    @Binding var countGoal: Int
    @Binding var hours: Int
    @Binding var minutes: Int
    
    @State private var timeDate: Date = Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var countText: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation state
    @Namespace private var animation
    
    private var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var secondaryColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }
    
    var body: some View {
        Section {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "trophy")
                        .foregroundStyle(.primary)
                        .frame(width: 24, height: 24)
                    
                    Text("daily_goal".localized)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        // Count Button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedType = .count
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if countGoal > 0 {
                                        countText = String(countGoal)
                                    } else {
                                        countText = ""
                                        countGoal = 0
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                    Image(systemName: "number")
                                        .font(.system(size: 12, weight: selectedType == .count ? .bold : .regular))
                                    Text("count".localized)
                                        .font(.system(size: 12, weight: selectedType == .count ? .bold : .regular))
                                }
                                .foregroundStyle(selectedType == .count ? primaryColor : secondaryColor)
                                .frame(height: 28)
                                .padding(.horizontal, 8)
                                .background {
                                    if selectedType == .count {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(backgroundColor)
                                            .matchedGeometryEffect(id: "TypeBackground", in: animation)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                        
                        // Time Button
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedType = .time
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if hours == 0 && minutes == 0 {
                                        hours = 1
                                        minutes = 0
                                    }
                                    updateTimeDateFromHoursAndMinutes()
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12, weight: selectedType == .time ? .bold : .regular))
                                    Text("time".localized)
                                        .font(.system(size: 12, weight: selectedType == .time ? .bold : .regular))
                                }
                                .foregroundStyle(selectedType == .time ? primaryColor : secondaryColor)
                                .frame(height: 28)
                                .padding(.horizontal, 8)
                                .background {
                                    if selectedType == .time {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(backgroundColor)
                                            .matchedGeometryEffect(id: "TypeBackground", in: animation)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(secondaryColor.opacity(0.5), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(height: 37)
                
                Divider()
                .padding(.leading, 24)
                
                HStack {
                    if selectedType == .count {
                        TextField("set_daily_goal".localized, text: $countText)
                            .keyboardType(.numberPad)
                            .tint(.primary)
                            .focused($isFocused)
                            .onChange(of: countText) { _, newValue in
                                if let number = Int(newValue) {
                                    countGoal = number
                                } else {
                                    countGoal = 0
                                }
                            }
                    } else {
                        Spacer()
                        DatePicker("", selection: $timeDate, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.primary)
                            .onChange(of: timeDate) { _, newValue in
                                updateHoursAndMinutesFromTimeDate()
                            }
                    }
                }
                .frame(height: 37)
                .padding(.leading, 28)
            }
        }
        .onAppear {
            updateTimeDateFromHoursAndMinutes()
            if selectedType == .count {
                countText = ""
                countGoal = 0
            }
        }
    }
    
    // Helper functions to sync between timeDate and hours/minutes
    private func updateHoursAndMinutesFromTimeDate() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: timeDate)
        hours = components.hour ?? 0
        minutes = components.minute ?? 0
    }
    
    private func updateTimeDateFromHoursAndMinutes() {
        timeDate = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    VStack(spacing: 40) {
        GoalSectionContent(
            selectedType: .constant(.count),
            countGoal: .constant(5),
            hours: .constant(1),
            minutes: .constant(30)
        )
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .preferredColorScheme(.light)
        
        GoalSectionContent(
            selectedType: .constant(.time),
            countGoal: .constant(5),
            hours: .constant(1),
            minutes: .constant(30)
        )
        .padding()
        .background(Color.black)
        .cornerRadius(12)
        .preferredColorScheme(.dark)
    }
    .padding()
}
