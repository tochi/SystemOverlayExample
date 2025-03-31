import SwiftUI
import RealityKit
import Combine

@Observable
class SubscriptionManager {
  private var cancellables = Set<AnyCancellable>()
  
  func store(_ cancellable: AnyCancellable) {
    cancellables.insert(cancellable)
  }
}

struct ImmersiveView: View {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
  @Environment(SystemOverlayViewModel.self) var viewModel

  @State private var subscriptionManager = SubscriptionManager()
  
  var body: some View {
    RealityView { content, attachments in
      await setupHandTracking(content: content)
      
      if let systemOverlayEntity = attachments.entity(for: "systemOverlay") {
        systemOverlayEntity.components.set(BillboardComponent())
        content.add(systemOverlayEntity)
      }
      
      HandGestureSystem.registerSystem()
      
      setupEventSubscriptions()
    } attachments: {
      Attachment(id: "systemOverlay") {
        SystemOverlayView()
          .environment(viewModel)
      }
    }
    .persistentSystemOverlays(.hidden)
  }
  
  private func setupHandTracking(content: RealityKit.RealityViewContent) async {
    let session = SpatialTrackingSession()
    let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
    await session.run(configuration)
    
    let rightIndexFinger = AnchorEntity(.hand(.right, location: .indexFingerTip))
    let rightThumbFinger = AnchorEntity(.hand(.right, location: .thumbTip))
    
    content.add(rightIndexFinger)
    content.add(rightThumbFinger)
  }
  
  private func setupEventSubscriptions() {
    let fingerCloseSubscription = HandGestureSystem.fingersClosePublisher
      .filter { $0 }
      .first()
      .sink { [viewModel] _ in
        Task { @MainActor in
          openWindow(id: viewModel.flipState == .front ? "FrontHand" : "BackHand")
          await dismissImmersiveSpace()
        }
      }
    
    let handFlipSubscription = HandGestureSystem.handFlipPublisher
      .sink { [viewModel] flipState in
        Task { @MainActor in
          viewModel.flipState = flipState
        }
      }
    
    Task { @MainActor in
      subscriptionManager.store(fingerCloseSubscription)
      subscriptionManager.store(handFlipSubscription)
    }
  }
}
