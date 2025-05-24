import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("themeMode") private var themeMode: Int = 0

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ReorderHabitsView()
                    } label: {
                        Label("reorder_habits".localized, systemImage: "list.bullet")
                    }
                    AppIconSection()
                    AppearanceSection()
                    WeekStartSection()
                    LanguageSection()
                }
                
                Section {
                    NavigationLink {
                        CloudKitSyncView()
                    } label: {
                        Label("icloud_sync".localized, systemImage: "icloud")
                    }
                    
                    NotificationsSection()
                    HapticsSection()
                }
                
                AboutSection()
                
                // Tymi - version ...
                Section {
                    VStack(spacing: 4) {
                        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                        
                        Image("TymiBlank")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                        
                        Text("Tymi – \("version".localized) \(version)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 4) {
                            Text("made_with".localized)
                            Image(systemName: "heart.fill")
                            Text("in_kyrgyzstan".localized)
                            Text("🇰🇬")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("settings".localized)
        }
        .preferredColorScheme(ThemeHelper.colorSchemeFromThemeMode(themeMode))
    }
}
