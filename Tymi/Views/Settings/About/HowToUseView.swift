import SwiftUI

struct HowToUseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Getting Started
                Group {
                    Text("howto_start_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("howto_start_body".localized)
                    
                    // Creating habits section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "1.square")
                                .font(.title2)
                            Text("howto_create_habit_title".localized)
                                .font(.headline)
                        }
                        Text("howto_create_habit_body".localized)
                        
                        HStack {
                            Image(systemName: "plus.fill")
                            Text("howto_tap_plus".localized)
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading)
                    }
                    .padding(.bottom, 5)
                    
                    // Types of habits
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "2.square")
                                .font(.title2)
                            Text("howto_habit_types_title".localized)
                                .font(.headline)
                        }
                        
                        Text("howto_habit_types_body".localized)
                        
                        HStack(alignment: .top, spacing: 15) {
                            VStack(alignment: .leading) {
                                Label("howto_count_type_title".localized, systemImage: "number")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("howto_count_type_body".localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading) {
                                Label("howto_time_type_title".localized, systemImage: "clock")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("howto_time_type_body".localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.bottom, 5)
                }
                
                // Tracking Progress
                Group {
                    Text("howto_tracking_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "3.square")
                                .font(.title2)
                            Text("howto_daily_tracking_title".localized)
                                .font(.headline)
                        }
                        Text("howto_daily_tracking_body".localized)
                    }
                    .padding(.bottom, 5)
                    
                    // Calendar
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "4.square")
                                .font(.title2)
                            Text("howto_calendar_title".localized)
                                .font(.headline)
                        }
                        Text("howto_calendar_body".localized)
                    }
                    .padding(.bottom, 5)
                }
                
                // Statistics
                Group {
                    Text("howto_statistics_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "5.square")
                                .font(.title2)
                            Text("howto_stats_detail_title".localized)
                                .font(.headline)
                        }
                        Text("howto_stats_detail_body".localized)
                    }
                    .padding(.bottom, 5)
                    
                    // Streaks
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "6.square")
                                .font(.title2)
                            Text("howto_streaks_title".localized)
                                .font(.headline)
                        }
                        Text("howto_streaks_body".localized)
                    }
                }
                
                // Settings and Customization
                Group {
                    Text("howto_settings_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "7.square")
                                .font(.title2)
                            Text("howto_personalization_title".localized)
                                .font(.headline)
                        }
                        Text("howto_personalization_body".localized)
                    }
                    .padding(.bottom, 5)
                    
                    // Notifications
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "8.square")
                                .font(.title2)
                            Text("howto_notifications_title".localized)
                                .font(.headline)
                        }
                        Text("howto_notifications_body".localized)
                    }
                }
                
                // Tips and Best Practices
                Group {
                    Text("howto_tips_title".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("howto_tip_1".localized, systemImage: "lightbulb.max")
                            .foregroundStyle(.primary, .yellow)
                        Label("howto_tip_2".localized, systemImage: "lightbulb.max")
                            .foregroundStyle(.primary, .yellow)
                        Label("howto_tip_3".localized, systemImage: "lightbulb.max")
                            .foregroundStyle(.primary, .yellow)
                        Label("howto_tip_4".localized, systemImage: "lightbulb.max")
                            .foregroundStyle(.primary, .yellow)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("how_to_use".localized)
        .navigationBarTitleDisplayMode(.large)
    }
}
