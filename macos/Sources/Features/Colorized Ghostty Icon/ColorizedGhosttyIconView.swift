import SwiftUI
import Cocoa

// For testing.
struct ColorizedGripIconView: View {
    var body: some View {
        Image(nsImage: ColorizedGripIcon(
            screenColors: [.purple, .blue],
            ghostColor: .yellow,
            frame: .aluminum
        ).makeImage()!)
    }
}
