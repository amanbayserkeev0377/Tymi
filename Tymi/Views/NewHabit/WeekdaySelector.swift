import SwiftUI

struct WeekdaySelector: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDays: Set<Int>
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "repeat")
                        .font(.body.weight(.medium))
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .frame(width: 26, height: 26)
                    
                    Text("Repeat")
                        .font(.body.weight(.regular))
                    
                    Spacer()
                    
                    Text(selectedDays.count == 7 ? "Every day" : "\(selectedDays.count) days")
                        .font(.subheadline)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
            }
            .buttonStyle(.plain)
            .frame(height: 56)
            .padding(.horizontal, 16)
            
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                    // Select/Deselect All Button
                    HStack {
                        Spacer()
                        Button(selectedDays.isEmpty ? "All" : "None") {
                            withAnimation(.easeInOut(duration: 0.3)) {
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
                    GeometryReader { geometry in
                        let availableWidth = geometry.size.width
                        let spacing: CGFloat = 8
                        let itemWidth = (availableWidth - (spacing * 6)) / 7
                        
                        HStack(spacing: spacing) {
                            ForEach(Weekday.allCases, id: \.self) { day in
                                let isSelected = selectedDays.contains(day.rawValue)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if selectedDays.contains(day.rawValue) {
                                            selectedDays.remove(day.rawValue)
                                        } else {
                                            selectedDays.insert(day.rawValue)
                                        }
                                    }
                                } label: {
                                    Text(day.shortName)
                                        .font(.system(size: 15, weight: .medium))
                                        .frame(width: itemWidth, height: itemWidth)
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
                    }
                    .frame(height: 40)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .glassCard()
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}
