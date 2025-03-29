import SwiftUI
import RealityFoundation

struct SystemOverlayView: View {
  @Environment(SystemOverlayViewModel.self) var systemOverlayViewModel
  
  var body: some View {
    Button {
    } label: {
      Image(systemName: systemOverlayViewModel.flipState == .front ? "star" : "moon.stars")
    }
    .frame(width: 30, height: 30)
    .cornerRadius(15)
    .rotation3DEffect(
      .degrees(systemOverlayViewModel.flipState == .front ? 0 : -180),
      axis: (x: 0, y: 1, z: 0)
    )
    .animation(.easeOut(duration: 0.2), value: systemOverlayViewModel.flipState)
  }
}

#Preview {
  SystemOverlayView()
    .environment(SystemOverlayViewModel())
    
}
