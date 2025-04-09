import SwiftUI
import Observation

enum FlipState {
  case front
  case back
}

@Observable class SystemOverlayViewModel {
  var flipState: FlipState = .front
}
