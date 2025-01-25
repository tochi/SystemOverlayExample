import SwiftUI

@main
struct SystemOverlayExampleApp: App {
    
  @State private var appModel = AppModel()
    
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(appModel)
    }

    WindowGroup("System Settings", id: "SystemSettings") {
      SystemSettingsView()
    }
    
    ImmersiveSpace(id: appModel.immersiveSpaceID) {
      ImmersiveView(gestureModel: HeartGestureModelContainer.handGestureModel)
        .environment(appModel)
        .onAppear {
          appModel.immersiveSpaceState = .open
        }
        .onDisappear {
          appModel.immersiveSpaceState = .closed
        }
    }
    .immersionStyle(selection: .constant(.mixed), in: .mixed)
  }
}

@MainActor
enum HeartGestureModelContainer {
    private(set) static var handGestureModel = HandGestureModel()
}

