import SwiftUI
import RealityKit
import Combine

class SubscriptionManager: ObservableObject {
  private var cancellables = Set<AnyCancellable>()
  
  func store(_ cancellable: AnyCancellable) {
    cancellables.insert(cancellable)
  }
}

struct ImmersiveView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
  @Environment(SystemOverlayViewModel.self) var systemOverlayViewModel
  @StateObject private var subscriptionManager = SubscriptionManager()
  private var cancellables = Set<AnyCancellable>()
  
  var body: some View {
    RealityView { content, attachments in
      let session = SpatialTrackingSession()
      let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
      await session.run(configuration)

      let rightIndexFinger = AnchorEntity(.hand(.right, location: .indexFingerTip))
      let rightThumbFinger = AnchorEntity(.hand(.right, location: .thumbTip))
      content.add(rightIndexFinger)
      content.add(rightThumbFinger)
      
      if let systemOverlayEntity = attachments.entity(for: "systemOverlay") {
        systemOverlayEntity.components.set(BillboardComponent())
        content.add(systemOverlayEntity)
      }

      HandGesturSystem.registerSystem()
      
      let cancellable1 = HandGesturSystem.fingersClosePublisher
        .filter { $0 }
        .first()
        .sink { _ in
          Task { @MainActor in
            openWindow(id: systemOverlayViewModel.flipState == .front ? "FrontHand" : "BackHand")
            await dismissImmersiveSpace()
          }
        }
      
      let cancellable2 = HandGesturSystem.handFlipPublisher
        .sink { flipState in
          Task { @MainActor in
            systemOverlayViewModel.flipState = flipState
          }
        }
      
      Task { @MainActor in
        subscriptionManager.store(cancellable1)
        subscriptionManager.store(cancellable2)
      }
    } attachments: {
      Attachment(id: "systemOverlay") {
        SystemOverlayView()
          .environment(systemOverlayViewModel)
      }
    }
    .persistentSystemOverlays(.hidden)
  }
}
