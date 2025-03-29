import SwiftUI
import RealityFoundation

struct SystemOverlayView: View {
  @Environment(SystemOverlayViewModel.self) var viewModel
  
  private let buttonSize: CGFloat = 30
  private let animationDuration: Double = 0.2
  
  var body: some View {
    Button {} label: {
      Image(systemName: viewModel.flipState == .front ? "star" : "moon.stars")
    }
    .frame(width: buttonSize, height: buttonSize)
    .cornerRadius(buttonSize / 2)
    .rotation3DEffect(
      .degrees(viewModel.flipState == .front ? 0 : -180),
      axis: (x: 0, y: 1, z: 0)
    )
    .animation(.easeOut(duration: animationDuration), value: viewModel.flipState)
  }
}

#Preview {
  SystemOverlayView()
    .environment(SystemOverlayViewModel())
}
