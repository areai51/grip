import SwiftUI
import GhosttyKit

@main
struct Grip_iOSApp: App {
    @StateObject private var ghostty_app: Grip.App

    init() {
        if ghostty_init(UInt(CommandLine.argc), CommandLine.unsafeArgv) != GHOSTTY_SUCCESS {
            preconditionFailure("Initialize grip backend failed")
        }
        _ghostty_app = StateObject(wrappedValue: Grip.App())
    }

    var body: some Scene {
        WindowGroup {
            iOS_GripTerminal()
                .environmentObject(ghostty_app)
        }
    }
}

struct iOS_GripTerminal: View {
    @EnvironmentObject private var ghostty_app: Grip.App

    var body: some View {
        ZStack {
            // Make sure that our background color extends to all parts of the screen
            Color(ghostty_app.config.backgroundColor).ignoresSafeArea()

            Grip.Terminal()
        }
    }
}

struct iOS_GripInitView: View {
    @EnvironmentObject private var ghostty_app: Grip.App

    var body: some View {
        VStack {
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 96)
            Text("Grip")
            Text("State: \(ghostty_app.readiness.rawValue)")
        }
        .padding()
    }
}
