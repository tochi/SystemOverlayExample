import SwiftUI
import RealityKit

struct ImmersiveView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
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
    .task {
      for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
        if appModel.tapped {
          await dismissImmersiveSpace()
          openWindow(id: "SystemSettings")
        }
      }
    }
    .persistentSystemOverlays(.hidden)
  }
}

#Preview(immersionStyle: .full) {
  ImmersiveView(gestureModel: HeartGestureModelContainer.handGestureModel)
    .environment(AppModel())
}
