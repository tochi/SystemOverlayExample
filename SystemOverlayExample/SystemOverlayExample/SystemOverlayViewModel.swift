import SwiftUI
import Observation

enum FlipState {
  case front
  case back
}

@Observable class SystemOverlayViewModel {
g   var flipState: FlipState = .front
}
