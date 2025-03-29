import SwiftUI

struct ContentView: View {
  @Environment(\.openImmersiveSpace) var openImmersiveSpace
  
  var body: some View {
    VStack {
      Text("Let's Start!")
      
      Button("Open Immersive Space") {
        Task {
          await openImmersiveSpace(id: "ImmersiveSpace")
        }
      }
      .padding()
      .buttonStyle(.bordered)
    }
    .onAppear {
      Task {
        await openImmersiveSpace(id: "ImmersiveSpace")
      }
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
}
