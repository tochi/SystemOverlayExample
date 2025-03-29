import SwiftUI

@main
struct SystemOverlayExampleApp: App {
  @State private var systemOverlayViewModel = SystemOverlayViewModel()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    
    WindowGroup("Front Hand", id: "FrontHand") {
      FrontHandView()
    }
    
    WindowGroup("Back Hand", id: "BackHand") {
      BackHandView()
    }
    
    ImmersiveSpace(id: "ImmersiveSpace") {
      ImmersiveView()
        .environment(systemOverlayViewModel)
    }
  }
}
