import SwiftUI

struct SystemOverlayView: View {
  @Environment(AppModel.self) private var appModel
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
  
  var body: some View {
    Button {
      Task { @MainActor in
        appModel.tapped.toggle()
        appModel.immersiveSpaceState = .inTransition
        await dismissImmersiveSpace()
        openWindow(id: "SystemSettings")
      }
    } label: {
      Image(systemName: appModel.tapped ? "star.fill" : "star")
    }
    .frame(width: 30, height: 30)
    .cornerRadius(15)
  }
}

#Preview {
  SystemOverlayView()
}
