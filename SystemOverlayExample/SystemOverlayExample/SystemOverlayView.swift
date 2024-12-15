import SwiftUI

struct SystemOverlayView: View {
  var body: some View {
    Button {
     print("Tapped")
    } label: {
      Image(systemName: "star")
    }
    .frame(width: 30, height: 30)
    .cornerRadius(15)
  }
}

#Preview {
  SystemOverlayView()
}
