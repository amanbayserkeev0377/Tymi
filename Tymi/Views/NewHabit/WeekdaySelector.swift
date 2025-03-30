import SwiftUI

struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Int>
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "repeat")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                    
                    Text("Repeat")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(selectedDays.count == 7 ? "Every day" : "\(selectedDays.count) days")
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .frame(height: 56)
            .padding(.horizontal, 16)
            
            if isExpanded {
                VStack(spacing: 16) {
                    // Select/Deselect All Button
                    HStack {
                        Spacer()
                        Button(selectedDays.isEmpty ? "All" : "None") {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedDays.isEmpty {
                                    selectedDays = Set(1...7)
                                } else {
                                    selectedDays.removeAll()
                                }
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                    
                    // Days Grid
                    HStack(spacing: 8) {
                        ForEach(Weekday.allCases, id: \.self) { day in
                            let isSelected = selectedDays.contains(day.rawValue)
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    if selectedDays.contains(day.rawValue) {
                                        selectedDays.remove(day.rawValue)
                                    } else {
                                        selectedDays.insert(day.rawValue)
                                    }
                                }
                            } label: {
                                Text(day.shortName)
                                    .font(.system(size: 15, weight: .medium))
                                    .frame(width: 40, height: 40)
                                    .background(isSelected ? Color.primary.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .glassCard()
        .animation(.spring(response: 0.3), value: isExpanded)
    }
}
