import SwiftUI
import Observation
import Combine

enum FlipState {
  case front
  case back
}

@Observable class SystemOverlayViewModel {  
  var flipState: FlipState = .front
}
