import SwiftUI
import RealityKit
import Combine

struct HandGesturSystem: System {
  static let fingersClosePublisher = PassthroughSubject<Bool, Never>()
  static let handFlipPublisher = PassthroughSubject<FlipState, Never>()
  private static let anchorQuery = EntityQuery(where: .has(AnchoringComponent.self))
  private static let systemOverlayQuery = EntityQuery(where: .has(BillboardComponent.self))
  private var anchorEntities: [AnchorEntity] = []
  private var flipState: FlipState = .front
  private var previousFlipSate: FlipState = .front
  private var isClosed = false
  private var previousIsClosed = false
  
  init(scene: RealityKit.Scene) { }
  
  mutating func update(context: SceneUpdateContext) {
    self.anchorEntities = context.entities(matching: Self.anchorQuery, updatingSystemWhen: .rendering)
      .compactMap { $0 as? AnchorEntity }
    
    self.flipState = detectHandFlip(anchorEntities: anchorEntities)
    if flipState != previousFlipSate {
      HandGesturSystem.handFlipPublisher.send(flipState)
      previousFlipSate = flipState
    }
    
    self.isClosed = areAnchorEntitiesClose(anchorEntities: anchorEntities)
    if isClosed != previousIsClosed {
      HandGesturSystem.fingersClosePublisher.send(isClosed)
      previousIsClosed = isClosed
    }
    
    for entity in context.entities(matching: Self.systemOverlayQuery, updatingSystemWhen: .rendering) {
      if let transform = rightHandFingerCenterTransform(anchorEntities: anchorEntities) {
        entity.transform = Transform(matrix: transform)
      }
    }
  }
    
  private func rightHandFingerCenterTransform(anchorEntities: [AnchorEntity]) -> simd_float4x4? {
    guard anchorEntities.count >= 2 else { return nil }

    let position1 = anchorEntityWorldPositin(anchorEntity: anchorEntities[0])
    let position2 = anchorEntityWorldPositin(anchorEntity: anchorEntities[1])

    let centerPosition = (position1 + position2) * 0.5
    
    var transform = matrix_identity_float4x4
    transform.columns.3 = SIMD4<Float>(centerPosition.x, centerPosition.y + 0.03, centerPosition.z, 1)
    return transform
  }
  
  private func areAnchorEntitiesClose(anchorEntities: [AnchorEntity]) -> Bool {
    guard anchorEntities.count >= 2 else { return false }
    
    let position1 = anchorEntityWorldPositin(anchorEntity: anchorEntities[0])
    let position2 = anchorEntityWorldPositin(anchorEntity: anchorEntities[1])
    
    let distance = simd_distance(position1, position2)

    return !distance.isZero && distance <= 0.03
  }
  
  private mutating func detectHandFlip(anchorEntities: [AnchorEntity]) -> FlipState {
    guard anchorEntities.count >= 2 else { return .front }
    
    let indexFingerPosition = anchorEntityWorldPositin(anchorEntity: anchorEntities[0])
    let thumbPosition = anchorEntityWorldPositin(anchorEntity: anchorEntities[1])
    
    let thumbToIndex = thumbPosition.x - indexFingerPosition.x
    
    return thumbToIndex > 0 ? .front : .back
  }
  
  private func anchorEntityWorldPositin(anchorEntity: AnchorEntity) -> SIMD3<Float> {
    anchorEntity.convert(position: anchorEntity.position, to: nil)
  }
}
