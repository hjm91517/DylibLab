import SwiftUI

@main
struct DylibLabApp: App {
    @StateObject private var projects: ProjectStore
    @StateObject private var settings: SettingsStore
    @StateObject private var ai: AIStore

    init() {
        let settingsStore = SettingsStore()
        _settings = StateObject(wrappedValue: settingsStore)
        _projects = StateObject(wrappedValue: ProjectStore())
        _ai = StateObject(wrappedValue: AIStore(settings: settingsStore))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(projects)
                .environmentObject(settings)
                .environmentObject(ai)
                .preferredColorScheme(.dark)
        }
    }
}
