import AppKit
import SwiftUI

@main
struct DocumentationScreenshotRenderer {
    @MainActor
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            fputs("usage: renderer OUTPUT_PNG APP_ICON_PNG\n", stderr)
            exit(2)
        }

        let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let iconPath = CommandLine.arguments[2]

        NSApplication.shared.appearance = NSAppearance(named: .aqua)
        if let icon = NSImage(contentsOfFile: iconPath) {
            NSApplication.shared.applicationIconImage = icon
        }

        UserDefaults.standard.set(KeepAliveTransport.https.rawValue, forKey: "transport")
        UserDefaults.standard.set("one.hust.edu.cn", forKey: "address")
        UserDefaults.standard.set(443, forKey: "port")
        UserDefaults.standard.set(KeepAliveHTTPMethod.get.rawValue, forKey: "httpMethod")
        UserDefaults.standard.set("/", forKey: "requestPath")
        UserDefaults.standard.set("", forKey: "tcpPayload")
        UserDefaults.standard.set(300, forKey: "intervalSeconds")
        UserDefaults.standard.set(true, forKey: "requireEasyConnect")
        UserDefaults.standard.set(true, forKey: "requireTunnelRoute")

        let controller = KeepAliveController()
        controller.prepareDocumentationScreenshot()

        let rootView = ContentView(controller: controller)
            .frame(width: 900, height: 820)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, .light)

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 900, height: 820)

        let window = NSWindow(
            contentRect: hostingView.frame,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = hostingView
        window.layoutIfNeeded()
        hostingView.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        hostingView.displayIfNeeded()

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 1800,
            pixelsHigh: 1640,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: [],
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw NSError(
                domain: "EasyConnectKeepAlive.Screenshot",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to allocate Retina bitmap"]
            )
        }
        bitmap.size = NSSize(width: 900, height: 820)
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(
                domain: "EasyConnectKeepAlive.Screenshot",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Unable to encode PNG"]
            )
        }

        try png.write(to: outputURL, options: .atomic)
        print(outputURL.path)
    }
}
