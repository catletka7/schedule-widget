import SwiftUI

@main
struct ScheduleAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ScheduleStore.shared)
        }
    }
}