import SwiftUI

@main
struct EasyConnectKeepAliveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 900, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
