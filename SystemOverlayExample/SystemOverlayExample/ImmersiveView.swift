import SwiftUI
import RealityKit

struct ImmersiveView: View {
  @Environment(AppModel.self) var appModel
  @ObservedObject var gestureModel: HandGestureModel

  var body: some View {
    RealityView { content in
      content.add(createSphere(name: "leftCenter"))
      content.add(createSphere(name: "rightCenter"))
    } update: { content in
      if let transform = gestureModel.leftHandFingerCenterTransform, let sphereEntity = findModelEntity(content: content, name: "leftCenter") {
        sphereEntity.transform = Transform(matrix: transform)
      }
      if let transform = gestureModel.rightHandFingerCenterTransform, let sphereEntity = findModelEntity(content: content, name: "rightCenter") {
        sphereEntity.transform = Transform(matrix: transform)
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
  
  private func createSphere(name: String) -> ModelEntity {
    let sphereMesh = MeshResource.generateSphere(radius: 0.005)
    let material = SimpleMaterial(color: .red, isMetallic: true)
    let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [material])
    sphereEntity.name = name
    return sphereEntity
  }
  
  private func findModelEntity(content: RealityViewContent, name: String) -> ModelEntity? {
    content.entities.first(where: { $0.name == name }) as? ModelEntity
  }
}

#Preview(immersionStyle: .full) {
  ImmersiveView(gestureModel: HeartGestureModelContainer.handGestureModel)
    .environment(AppModel())
}
