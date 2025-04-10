import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = AppearanceSettingsViewModel()
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color Scheme", selection: $viewModel.colorSchemePreference) {
                        ForEach(ColorSchemePreference.allCases, id: \.self) { preference in
                            Text(preference.title).tag(preference)
                        }
                    }
                    
                    Picker("App Icon", selection: $viewModel.appIconPreference) {
                        ForEach(AppIconPreference.allCases, id: \.self) { preference in
                            Text(preference.title).tag(preference)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}
