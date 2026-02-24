import os
import SwiftUI
import GhosttyKit

struct Grip {
    // The primary logger used by the GripKit libraries.
    static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "grip"
    )

    // All the notifications that will be emitted will be put here.
    struct Notification {}

    // The user notification category identifier
    static let userNotificationCategory = "com.mitchellh.grip.userNotification"

    // The user notification "Show" action
    static let userNotificationActionShow = "com.mitchellh.grip.userNotification.Show"
}

// MARK: C Extensions

/// A command is fully self-contained so it is Sendable.
extension ghostty_command_s: @unchecked @retroactive Sendable {}

/// A surface is sendable because it is just a reference type. Using the surface in parameters
/// may be unsafe but the value itself is safe to send across threads.
extension ghostty_surface_t: @unchecked @retroactive Sendable {}

// MARK: Build Info

extension Grip {
    struct Info {
        var mode: ghostty_build_mode_e
        var version: String
    }

    static var info: Info {
        let raw = ghostty_info()
        let version = NSString(
            bytes: raw.version,
            length: Int(raw.version_len),
            encoding: NSUTF8StringEncoding
        ) ?? "unknown"

        return Info(mode: raw.build_mode, version: String(version))
    }
}

// MARK: General Helpers

extension Grip {
    enum LaunchSource: String {
        case cli
        case app
        case zig_run
    }

    /// Returns the mechanism that launched the app. This is based on an env var so
    /// its up to the env var being set in the correct circumstance.
    static var launchSource: LaunchSource {
        guard let envValue = ProcessInfo.processInfo.environment["GHOSTTY_MAC_LAUNCH_SOURCE"] else {
            // We default to the CLI because the app bundle always sets the
            // source. If its unset we assume we're in a CLI environment.
            return .cli
        }

        // If the env var is set but its unknown then we default back to the app.
        return LaunchSource(rawValue: envValue) ?? .app
    }
}

// MARK: Swift Types for C Types

extension Grip {
    class AllocatedString {
        private let cString: ghostty_string_s

        init(_ c: ghostty_string_s) {
            self.cString = c
        }

        var string: String {
            guard let ptr = cString.ptr else { return "" }
            let data = Data(bytes: ptr, count: Int(cString.len))
            return String(data: data, encoding: .utf8) ?? ""
        }

        deinit {
            ghostty_string_free(cString)
        }
    }
}

extension Grip {
    enum SetFloatWIndow {
        case on
        case off
        case toggle

        static func from(_ c: ghostty_action_float_window_e) -> Self? {
            switch (c) {
            case GHOSTTY_FLOAT_WINDOW_ON:
                return .on

            case GHOSTTY_FLOAT_WINDOW_OFF:
                return .off

            case GHOSTTY_FLOAT_WINDOW_TOGGLE:
                return .toggle

            default:
                return nil
            }
        }
    }

    enum SetSecureInput {
        case on
        case off
        case toggle

        static func from(_ c: ghostty_action_secure_input_e) -> Self? {
            switch (c) {
            case GHOSTTY_SECURE_INPUT_ON:
                return .on

            case GHOSTTY_SECURE_INPUT_OFF:
                return .off

            case GHOSTTY_SECURE_INPUT_TOGGLE:
                return .toggle

            default:
                return nil
            }
        }
    }

    /// An enum that is used for the directions that a split focus event can change.
    enum SplitFocusDirection {
        case previous, next, up, down, left, right

        /// Initialize from a Grip API enum.
        static func from(direction: ghostty_action_goto_split_e) -> Self? {
            switch (direction) {
            case GHOSTTY_GOTO_SPLIT_PREVIOUS:
                return .previous

            case GHOSTTY_GOTO_SPLIT_NEXT:
                return .next

            case GHOSTTY_GOTO_SPLIT_UP:
                return .up

            case GHOSTTY_GOTO_SPLIT_DOWN:
                return .down

            case GHOSTTY_GOTO_SPLIT_LEFT:
                return .left

            case GHOSTTY_GOTO_SPLIT_RIGHT:
                return .right

            default:
                return nil
            }
        }

        func toNative() -> ghostty_action_goto_split_e {
            switch (self) {
            case .previous:
                return GHOSTTY_GOTO_SPLIT_PREVIOUS

            case .next:
                return GHOSTTY_GOTO_SPLIT_NEXT

            case .up:
                return GHOSTTY_GOTO_SPLIT_UP

            case .down:
                return GHOSTTY_GOTO_SPLIT_DOWN

            case .left:
                return GHOSTTY_GOTO_SPLIT_LEFT

            case .right:
                return GHOSTTY_GOTO_SPLIT_RIGHT
            }
        }
    }

    /// Enum used for resizing splits. This is the direction the split divider will move.
    enum SplitResizeDirection {
        case up, down, left, right

        static func from(direction: ghostty_action_resize_split_direction_e) -> Self? {
            switch (direction) {
            case GHOSTTY_RESIZE_SPLIT_UP:
                return .up;
            case GHOSTTY_RESIZE_SPLIT_DOWN:
                return .down;
            case GHOSTTY_RESIZE_SPLIT_LEFT:
                return .left;
            case GHOSTTY_RESIZE_SPLIT_RIGHT:
                return .right;
            default:
                return nil
            }
        }

        func toNative() -> ghostty_action_resize_split_direction_e {
            switch (self) {
            case .up:
                return GHOSTTY_RESIZE_SPLIT_UP;
            case .down:
                return GHOSTTY_RESIZE_SPLIT_DOWN;
            case .left:
                return GHOSTTY_RESIZE_SPLIT_LEFT;
            case .right:
                return GHOSTTY_RESIZE_SPLIT_RIGHT;
            }
        }
    }
}

#if canImport(AppKit)
// MARK: SplitFocusDirection Extensions

extension Grip.SplitFocusDirection {
    /// Convert to a SplitTree.FocusDirection for the given ViewType.
    func toSplitTreeFocusDirection<ViewType>() -> SplitTree<ViewType>.FocusDirection {
        switch self {
        case .previous:
            return .previous

        case .next:
            return .next

        case .up:
            return .spatial(.up)

        case .down:
            return .spatial(.down)

        case .left:
            return .spatial(.left)

        case .right:
            return .spatial(.right)
        }
    }
}
#endif

extension Grip {
    /// The type of a clipboard request
    enum ClipboardRequest {
        /// A direct paste of clipboard contents
        case paste

        /// An application is attempting to read from the clipboard using OSC 52
        case osc_52_read

        /// An application is attempting to write to the clipboard using OSC 52
        case osc_52_write(OSPasteboard?)

        /// The text to show in the clipboard confirmation prompt for a given request type
        func text() -> String {
            switch (self) {
            case .paste:
                return """
                Pasting this text to the terminal may be dangerous as it looks like some commands may be executed.
                """
            case .osc_52_read:
                return """
                An application is attempting to read from the clipboard.
                The current clipboard contents are shown below.
                """
            case .osc_52_write:
                return """
                An application is attempting to write to the clipboard.
                The content to write is shown below.
                """
            }
        }

        static func from(request: ghostty_clipboard_request_e) -> ClipboardRequest? {
            switch (request) {
            case GHOSTTY_CLIPBOARD_REQUEST_PASTE:
                return .paste
            case GHOSTTY_CLIPBOARD_REQUEST_OSC_52_READ:
                return .osc_52_read
            case GHOSTTY_CLIPBOARD_REQUEST_OSC_52_WRITE:
                return .osc_52_write(nil)
            default:
                return nil
            }
        }
    }
    
    struct ClipboardContent {
        let mime: String
        let data: String
        
        static func from(content: ghostty_clipboard_content_s) -> ClipboardContent? {
            guard let mimePtr = content.mime,
                  let dataPtr = content.data else {
                return nil
            }
            
            return ClipboardContent(
                mime: String(cString: mimePtr),
                data: String(cString: dataPtr)
            )
        }
    }

    /// macos-icon
    enum MacOSIcon: String, Sendable {
        case official
        case blueprint
        case chalkboard
        case glass
        case holographic
        case microchip
        case paper
        case retro
        case xray
        case custom
        case customStyle = "custom-style"

        /// Bundled asset name for built-in icons
        var assetName: String? {
            switch self {
            case .official: return nil
            case .blueprint: return "BlueprintImage"
            case .chalkboard: return "ChalkboardImage"
            case .microchip: return "MicrochipImage"
            case .glass: return "GlassImage"
            case .holographic: return "HolographicImage"
            case .paper: return "PaperImage"
            case .retro: return "RetroImage"
            case .xray: return "XrayImage"
            case .custom, .customStyle: return nil
            }
        }
    }

    /// macos-icon-frame
    enum MacOSIconFrame: String {
        case aluminum
        case beige
        case plastic
        case chrome
    }

    /// Enum for the macos-window-buttons config option
    enum MacOSWindowButtons: String {
        case visible
        case hidden
    }

    /// Enum for the macos-titlebar-proxy-icon config option
    enum MacOSTitlebarProxyIcon: String {
        case visible
        case hidden
    }

    /// Enum for auto-update-channel config option
    enum AutoUpdateChannel: String {
        case tip
        case stable
    }
}

// MARK: Surface Notification

extension Notification.Name {
    /// Configuration change. If the object is nil then it is app-wide. Otherwise its surface-specific.
    static let gripConfigDidChange = Notification.Name("com.mitchellh.grip.configDidChange")
    static let GripConfigChangeKey = gripConfigDidChange.rawValue

    /// Color change. Object is the surface changing.
    static let gripColorDidChange = Notification.Name("com.mitchellh.grip.gripColorDidChange")
    static let GripColorChangeKey = gripColorDidChange.rawValue

    /// Goto tab. Has tab index in the userinfo.
    static let gripMoveTab = Notification.Name("com.mitchellh.grip.moveTab")
    static let GripMoveTabKey = gripMoveTab.rawValue

    /// Close tab
    static let gripCloseTab = Notification.Name("com.mitchellh.grip.closeTab")

    /// Close other tabs
    static let gripCloseOtherTabs = Notification.Name("com.mitchellh.grip.closeOtherTabs")

    /// Close tabs to the right of the focused tab
    static let gripCloseTabsOnTheRight = Notification.Name("com.mitchellh.grip.closeTabsOnTheRight")

    /// Close window
    static let gripCloseWindow = Notification.Name("com.mitchellh.grip.closeWindow")

    /// Resize the window to a default size.
    static let gripResetWindowSize = Notification.Name("com.mitchellh.grip.resetWindowSize")

    /// Ring the bell
    static let gripBellDidRing = Notification.Name("com.mitchellh.grip.gripBellDidRing")

    /// Readonly mode changed
    static let gripDidChangeReadonly = Notification.Name("com.mitchellh.grip.didChangeReadonly")
    static let ReadonlyKey = gripDidChangeReadonly.rawValue + ".readonly"
    static let gripCommandPaletteDidToggle = Notification.Name("com.mitchellh.grip.commandPaletteDidToggle")

    /// Toggle maximize of current window
    static let gripMaximizeDidToggle = Notification.Name("com.mitchellh.grip.maximizeDidToggle")

    /// Notification sent when scrollbar updates
    static let gripDidUpdateScrollbar = Notification.Name("com.mitchellh.grip.didUpdateScrollbar")
    static let ScrollbarKey = gripDidUpdateScrollbar.rawValue + ".scrollbar"

    /// Focus the search field
    static let gripSearchFocus = Notification.Name("com.mitchellh.grip.searchFocus")
}

// NOTE: I am moving all of these to Notification.Name extensions over time. This
// namespace was the old namespace.
extension Grip.Notification {
    /// Used to pass a configuration along when creating a new tab/window/split.
    static let NewSurfaceConfigKey = "com.mitchellh.grip.newSurfaceConfig"

    /// Posted when a new split is requested. The sending object will be the surface that had focus. The
    /// userdata has one key "direction" with the direction to split to.
    static let gripNewSplit = Notification.Name("com.mitchellh.grip.newSplit")

    /// Close the calling surface.
    static let gripCloseSurface = Notification.Name("com.mitchellh.grip.closeSurface")

    /// Focus previous/next split. Has a SplitFocusDirection in the userinfo.
    static let gripFocusSplit = Notification.Name("com.mitchellh.grip.focusSplit")
    static let SplitDirectionKey = gripFocusSplit.rawValue

    /// Goto tab. Has tab index in the userinfo.
    static let gripGotoTab = Notification.Name("com.mitchellh.grip.gotoTab")
    static let GotoTabKey = gripGotoTab.rawValue

    /// New tab. Has base surface config requested in userinfo.
    static let gripNewTab = Notification.Name("com.mitchellh.grip.newTab")

    /// New window. Has base surface config requested in userinfo.
    static let gripNewWindow = Notification.Name("com.mitchellh.grip.newWindow")

    /// Present terminal. Bring the surface's window to focus without activating the app.
    static let gripPresentTerminal = Notification.Name("com.mitchellh.grip.presentTerminal")

    /// Toggle fullscreen of current window
    static let gripToggleFullscreen = Notification.Name("com.mitchellh.grip.toggleFullscreen")
    static let FullscreenModeKey = gripToggleFullscreen.rawValue

    /// Notification sent to toggle split maximize/unmaximize.
    static let didToggleSplitZoom = Notification.Name("com.mitchellh.grip.didToggleSplitZoom")

    /// Notification
    static let didReceiveInitialWindowFrame = Notification.Name("com.mitchellh.grip.didReceiveInitialWindowFrame")
    static let FrameKey = "com.mitchellh.grip.frame"

    /// Notification to render the inspector for a surface
    static let inspectorNeedsDisplay = Notification.Name("com.mitchellh.grip.inspectorNeedsDisplay")

    /// Notification to show/hide the inspector
    static let didControlInspector = Notification.Name("com.mitchellh.grip.didControlInspector")

    static let confirmClipboard = Notification.Name("com.mitchellh.grip.confirmClipboard")
    static let ConfirmClipboardStrKey = confirmClipboard.rawValue + ".str"
    static let ConfirmClipboardStateKey = confirmClipboard.rawValue + ".state"
    static let ConfirmClipboardRequestKey = confirmClipboard.rawValue + ".request"

    /// Notification sent to the active split view to resize the split.
    static let didResizeSplit = Notification.Name("com.mitchellh.grip.didResizeSplit")
    static let ResizeSplitDirectionKey = didResizeSplit.rawValue + ".direction"
    static let ResizeSplitAmountKey = didResizeSplit.rawValue + ".amount"

    /// Notification sent to the split root to equalize split sizes
    static let didEqualizeSplits = Notification.Name("com.mitchellh.grip.didEqualizeSplits")

    /// Notification that renderer health changed
    static let didUpdateRendererHealth = Notification.Name("com.mitchellh.grip.didUpdateRendererHealth")

    /// Notifications related to key sequences
    static let didContinueKeySequence = Notification.Name("com.mitchellh.grip.didContinueKeySequence")
    static let didEndKeySequence = Notification.Name("com.mitchellh.grip.didEndKeySequence")
    static let KeySequenceKey = didContinueKeySequence.rawValue + ".key"

    /// Notifications related to key tables
    static let didChangeKeyTable = Notification.Name("com.mitchellh.grip.didChangeKeyTable")
    static let KeyTableKey = didChangeKeyTable.rawValue + ".action"
}

// Make the input enum hashable.
extension ghostty_input_key_e : @retroactive Hashable {}
