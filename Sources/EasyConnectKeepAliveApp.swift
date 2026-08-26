import SwiftUI

@main
struct EasyConnectKeepAliveApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 720, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
