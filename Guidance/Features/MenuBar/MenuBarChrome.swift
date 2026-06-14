import AppKit
import SwiftUI

// MARK: - Pointer cursor

/// Shows the pointing-hand cursor while hovered - the native affordance a
/// `MenuBarExtra(.window)` popover's custom SwiftUI controls otherwise lack. The
/// push/pop is balanced via local state (and cleaned up on disappear) so a
/// dismissal mid-hover can't leave the cursor stuck.
private struct PointerCursorModifier: ViewModifier {
  @State private var pushed = false

  func body(content: Content) -> some View {
    content
      .onHover { inside in
        if inside, !pushed {
          NSCursor.pointingHand.push()
          pushed = true
        } else if !inside, pushed {
          NSCursor.pop()
          pushed = false
        }
      }
      .onDisappear {
        if pushed {
          NSCursor.pop()
          pushed = false
        }
      }
  }
}

extension View {
  /// Pointing-hand cursor on hover for a clickable control in the dropdown.
  func menuPointerCursor() -> some View {
    modifier(PointerCursorModifier())
  }
}
