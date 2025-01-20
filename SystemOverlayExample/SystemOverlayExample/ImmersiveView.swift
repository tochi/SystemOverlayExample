import SwiftUI
import RealityKit
import ARKit

struct ImmersiveView: View {
  @Environment(AppModel.self) var appModel
  @ObservedObject var gestureModel: HandGestureModel
  @State private var buttonPosition: SIMD3<Float> = [0, 0, 1]
  var systemOverlayView = SystemOverlayView()

  var body: some View {
    RealityView { content, _  in
    } update: { content, attachments  in
      if let systemOverlayEntity = attachments.entity(for: "systemOverlay"), let transform = gestureModel.rightHandFingerCenterTransform {
        appModel.tapped = gestureModel.isRightHandFingersTouching()
        systemOverlayEntity.transform = Transform(matrix: transform)
        content.add(systemOverlayEntity)
      }
    } attachments: {
      Attachment(id: "systemOverlay") {
        SystemOverlayView()
      }
    }
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
