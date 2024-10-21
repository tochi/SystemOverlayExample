import SwiftUI
import RealityKit

struct ImmersiveView: View {
  @Environment(AppModel.self) var appModel

  var body: some View {
    RealityView { content in
    }
  }
}

#Preview(immersionStyle: .full) {
  ImmersiveView()
    .environment(AppModel())
}
