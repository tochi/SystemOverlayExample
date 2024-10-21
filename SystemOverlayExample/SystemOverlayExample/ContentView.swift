import SwiftUI
import RealityKit

struct ContentView: View {

  var body: some View {
    VStack {
      ToggleImmersiveSpaceButton()
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
    .environment(AppModel())
}
