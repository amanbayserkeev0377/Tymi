import SwiftUI

struct GoalSection: View {
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
                    
                    Text("Daily Goal")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        // Count Button
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                                selectedType = .count
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    countText = ""
                                    countGoal = 0
                                }
                            }
                        } label: {
                            // Two separate Text views - one for each state
                            ZStack {
                                // Bold text for selected state
                                HStack(spacing: 4) {
                                    Image(systemName: "number")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Count")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(primaryColor)
                                .opacity(selectedType == .count ? 1 : 0)
                                
                                // Regular text for unselected state
                                HStack(spacing: 4) {
                                    Image(systemName: "number")
                                        .font(.system(size: 12, weight: .regular))
                                    Text("Count")
                                        .font(.system(size: 12, weight: .regular))
                                }
                                .foregroundStyle(secondaryColor)
                                .opacity(selectedType == .count ? 0 : 1)
                            }
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
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                                selectedType = .time
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    hours = 1
                                    minutes = 0
                                    updateTimeDateFromHoursAndMinutes()
                                }
                            }
                        } label: {
                            // Two separate Text views - one for each state
                            ZStack {
                                // Bold text for selected state
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Time")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(primaryColor)
                                .opacity(selectedType == .time ? 1 : 0)
                                
                                // Regular text for unselected state
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12, weight: .regular))
                                    Text("Time")
                                        .font(.system(size: 12, weight: .regular))
                                }
                                .foregroundStyle(secondaryColor)
                                .opacity(selectedType == .time ? 0 : 1)
                            }
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
                
                HStack {
                    if selectedType == .count {
                        TextField("Set your daily goal", text: $countText)
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
        GoalSection(
            selectedType: .constant(.count),
            countGoal: .constant(5),
            hours: .constant(1),
            minutes: .constant(30)
        )
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .preferredColorScheme(.light)
        
        GoalSection(
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
