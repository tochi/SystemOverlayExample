import SwiftUI
import RealityKit
import ARKit

struct ImmersiveView: View {
  @Environment(AppModel.self) var appModel
  @ObservedObject var gestureModel: HandGestureModel
  @State private var buttonPosition: SIMD3<Float> = [0, 0, 1]

  var body: some View {
    RealityView { content, _  in
    } update: { content, attachments  in
      if let textEntity = attachments.entity(for: "textAttachment"), let transform = gestureModel.rightHandFingerCenterTransform {
        textEntity.transform = Transform(matrix: transform)
        content.add(textEntity)
      }
    } attachments: {
      Attachment(id: "textAttachment") {
        Text("Hello World")
          .frame(width: 200, height: 100)
          .background(Color.blue)
      }
    }
    .overlay(
      Button(action: {
        print("Button tapped!")
      }) {
        Text("Follow Me")
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
        .position(x: CGFloat(buttonPosition.x), y: CGFloat(buttonPosition.y))
    )
    .task {
      await gestureModel.start()
    }
    .task {
      await gestureModel.publishHandTrackingUpdates()
    }
    .task {
      await gestureModel.monitorSessionEvents()
    }
    .persistentSystemOverlays(.hidden)
  }
}

#Preview(immersionStyle: .full) {
  ImmersiveView(gestureModel: HeartGestureModelContainer.handGestureModel)
    .environment(AppModel())
}
