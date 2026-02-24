import Foundation

extension Grip {
    /// This is a delegate that should be applied to your global app delegate for GripKit
    /// to perform app-global operations.
    protocol Delegate {
        /// Look up a surface within the application by ID.
        func gripSurface(id: UUID) -> SurfaceView?
    }
}
