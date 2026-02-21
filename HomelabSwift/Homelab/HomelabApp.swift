import SwiftUI

@main
struct HomelabApp: App {
    @State private var servicesStore = ServicesStore()
    @State private var settingsStore = SettingsStore()
    @State private var localizer = Localizer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(servicesStore)
                .environment(settingsStore)
                .environment(localizer)
                .task {
                    // Sync localizer with persisted language
                    localizer.language = settingsStore.language
                    await servicesStore.initialize()
                }
        }
    }
}
