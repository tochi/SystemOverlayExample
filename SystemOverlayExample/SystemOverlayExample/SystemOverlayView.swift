import SwiftUI

struct SystemOverlayView: View {
  @Environment(AppModel.self) private var appModel
  
  var body: some View {
    Button {
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
