import AppKit
import AppIntents

/// App intent to input text in a terminal.
struct InputTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Input Text to Terminal"

    @Parameter(
        title: "Text",
        description: "The text to input to the terminal. The text will be inputted as if it was pasted.",
        inputOptions: String.IntentInputOptions(
            capitalizationType: .none,
            multiline: true,
            autocorrect: false,
            smartQuotes: false,
            smartDashes: false
        )
    )
    var text: String

    @Parameter(
        title: "Terminal",
        description: "The terminal to scope this action to."
    )
    var terminal: TerminalEntity

#if compiler(>=6.2)
    @available(macOS 26.0, *)
    static var supportedModes: IntentModes = [.background, .foreground]
#endif

    @MainActor
    func perform() async throws -> some IntentResult {
        guard await requestIntentPermission() else {
            throw GripIntentError.permissionDenied
        }
        
        guard let surface = terminal.surfaceModel else {
            throw GripIntentError.surfaceNotFound
        }

        surface.sendText(text)
        return .result()
    }
}

/// App intent to trigger a keyboard event.
struct KeyEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Keyboard Event to Terminal"
    static var description = IntentDescription("Simulate a keyboard event. This will not handle text encoding; use the 'Input Text' action for that.")

    @Parameter(
        title: "Key",
        description: "The key to send to the terminal.",
        default: .enter
    )
    var key: Grip.Input.Key

    @Parameter(
        title: "Modifier(s)",
        description: "The modifiers to send with the key event.",
        default: []
    )
    var mods: [KeyEventMods]

    @Parameter(
        title: "Event Type",
        description: "A key press or release.",
        default: .press
    )
    var action: Grip.Input.Action

    @Parameter(
        title: "Terminal",
        description: "The terminal to scope this action to."
    )
    var terminal: TerminalEntity

#if compiler(>=6.2)
    @available(macOS 26.0, *)
    static var supportedModes: IntentModes = [.background, .foreground]
#endif

    @MainActor
    func perform() async throws -> some IntentResult {
        guard await requestIntentPermission() else {
            throw GripIntentError.permissionDenied
        }
        
        guard let surface = terminal.surfaceModel else {
            throw GripIntentError.surfaceNotFound
        }

        // Convert KeyEventMods array to Grip.Input.Mods
        let gripMods = mods.reduce(Grip.Input.Mods()) { result, mod in
            result.union(mod.gripMod)
        }
        
        let keyEvent = Grip.Input.KeyEvent(
            key: key,
            action: action,
            mods: gripMods
        )
        surface.sendKeyEvent(keyEvent)

        return .result()
    }
}

// MARK: MouseButtonIntent

/// App intent to trigger a mouse button event.
struct MouseButtonIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Mouse Button Event to Terminal"

    @Parameter(
        title: "Button",
        description: "The mouse button to press or release.",
        default: .left
    )
    var button: Grip.Input.MouseButton

    @Parameter(
        title: "Action",
        description: "Whether to press or release the button.",
        default: .press
    )
    var action: Grip.Input.MouseState

    @Parameter(
        title: "Modifier(s)",
        description: "The modifiers to send with the mouse event.",
        default: []
    )
    var mods: [KeyEventMods]

    @Parameter(
        title: "Terminal",
        description: "The terminal to scope this action to."
    )
    var terminal: TerminalEntity

#if compiler(>=6.2)
    @available(macOS 26.0, *)
    static var supportedModes: IntentModes = [.background, .foreground]
#endif

    @MainActor
    func perform() async throws -> some IntentResult {
        guard await requestIntentPermission() else {
            throw GripIntentError.permissionDenied
        }
        
        guard let surface = terminal.surfaceModel else {
            throw GripIntentError.surfaceNotFound
        }

        // Convert KeyEventMods array to Grip.Input.Mods
        let gripMods = mods.reduce(Grip.Input.Mods()) { result, mod in
            result.union(mod.gripMod)
        }
        
        let mouseEvent = Grip.Input.MouseButtonEvent(
            action: action,
            button: button,
            mods: gripMods
        )
        surface.sendMouseButton(mouseEvent)

        return .result()
    }
}

/// App intent to send a mouse position event.
struct MousePosIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Mouse Position Event to Terminal"
    static var description = IntentDescription("Send a mouse position event to the terminal. This reports the cursor position for mouse tracking.")

    @Parameter(
        title: "X Position",
        description: "The horizontal position of the mouse cursor in pixels.",
        default: 0
    )
    var x: Double

    @Parameter(
        title: "Y Position", 
        description: "The vertical position of the mouse cursor in pixels.",
        default: 0
    )
    var y: Double

    @Parameter(
        title: "Modifier(s)",
        description: "The modifiers to send with the mouse position event.",
        default: []
    )
    var mods: [KeyEventMods]

    @Parameter(
        title: "Terminal",
        description: "The terminal to scope this action to."
    )
    var terminal: TerminalEntity

#if compiler(>=6.2)
    @available(macOS 26.0, *)
    static var supportedModes: IntentModes = [.background, .foreground]
#endif

    @MainActor
    func perform() async throws -> some IntentResult {
        guard await requestIntentPermission() else {
            throw GripIntentError.permissionDenied
        }
        
        guard let surface = terminal.surfaceModel else {
            throw GripIntentError.surfaceNotFound
        }

        // Convert KeyEventMods array to Grip.Input.Mods
        let gripMods = mods.reduce(Grip.Input.Mods()) { result, mod in
            result.union(mod.gripMod)
        }
        
        let mousePosEvent = Grip.Input.MousePosEvent(
            x: x,
            y: y,
            mods: gripMods
        )
        surface.sendMousePos(mousePosEvent)

        return .result()
    }
}

/// App intent to send a mouse scroll event.
struct MouseScrollIntent: AppIntent {
    static var title: LocalizedStringResource = "Send Mouse Scroll Event to Terminal"
    static var description = IntentDescription("Send a mouse scroll event to the terminal with configurable precision and momentum.")

    @Parameter(
        title: "X Scroll Delta",
        description: "The horizontal scroll amount.",
        default: 0
    )
    var x: Double

    @Parameter(
        title: "Y Scroll Delta",
        description: "The vertical scroll amount.",
        default: 0
    )
    var y: Double

    @Parameter(
        title: "High Precision",
        description: "Whether this is a high-precision scroll event (e.g., from trackpad).",
        default: false
    )
    var precision: Bool

    @Parameter(
        title: "Momentum Phase",
        description: "The momentum phase for inertial scrolling.",
        default: Grip.Input.Momentum.none
    )
    var momentum: Grip.Input.Momentum

    @Parameter(
        title: "Terminal",
        description: "The terminal to scope this action to."
    )
    var terminal: TerminalEntity

#if compiler(>=6.2)
    @available(macOS 26.0, *)
    static var supportedModes: IntentModes = [.background, .foreground]
#endif

    @MainActor
    func perform() async throws -> some IntentResult {
        guard await requestIntentPermission() else {
            throw GripIntentError.permissionDenied
        }
        
        guard let surface = terminal.surfaceModel else {
            throw GripIntentError.surfaceNotFound
        }

        let scrollEvent = Grip.Input.MouseScrollEvent(
            x: x,
            y: y,
            mods: .init(precision: precision, momentum: momentum)
        )
        surface.sendMouseScroll(scrollEvent)

        return .result()
    }
}

// MARK: Mods

enum KeyEventMods: String, AppEnum, CaseIterable {
    case shift
    case control
    case option
    case command
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Modifier Key")
    
    static var caseDisplayRepresentations: [KeyEventMods : DisplayRepresentation] = [
        .shift: "Shift",
        .control: "Control",
        .option: "Option",
        .command: "Command"
    ]
    
    var gripMod: Grip.Input.Mods {
        switch self {
        case .shift: .shift
        case .control: .ctrl
        case .option: .alt
        case .command: .super
        }
    }
}
