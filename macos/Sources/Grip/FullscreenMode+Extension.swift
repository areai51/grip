import GhosttyKit

extension FullscreenMode {
    /// Initialize from a Grip fullscreen action.
    static func from(grip: ghostty_action_fullscreen_e) -> Self? {
        return switch grip {
        case GHOSTTY_FULLSCREEN_NATIVE:
                .native

        case GHOSTTY_FULLSCREEN_NON_NATIVE:
                .nonNative

        case GHOSTTY_FULLSCREEN_NON_NATIVE_VISIBLE_MENU:
                .nonNativeVisibleMenu

        case GHOSTTY_FULLSCREEN_NON_NATIVE_PADDED_NOTCH:
                .nonNativePaddedNotch

        default:
            nil
        }
    }
}
