import AppKit

// MARK: Grip Delegate

/// This implements the Grip app delegate protocol which is used by the Grip
/// APIs for app-global information.
extension AppDelegate: Grip.Delegate {
    func gripSurface(id: UUID) -> Grip.SurfaceView? {
        for window in NSApp.windows {
            guard let controller = window.windowController as? BaseTerminalController else {
                continue
            }
            
            for surface in controller.surfaceTree {
                if surface.id == id {
                    return surface
                }
            }
        }
        
        return nil
    }
}
