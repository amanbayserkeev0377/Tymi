import SwiftUI

struct StartDateSection: View {
    @Binding var startDate: Date
    
    var body: some View {
        HStack {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(AppColorManager.shared.selectedColor.color)
                .font(.system(size: 22))
                .frame(width: 30)
                .clipped()
                      
            Text("start_date".localized)
            
            Spacer()
            
            DatePicker(
                "",
                selection: $startDate,
                in: HistoryLimits.datePickerRange,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
        }
    }
}
