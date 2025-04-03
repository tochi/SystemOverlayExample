import SwiftUI
import RealityKit
import Combine

struct HandGestureSystem: System {
  static let fingersClosePublisher = PassthroughSubject<Bool, Never>()
  static let handFlipPublisher = PassthroughSubject<FlipState, Never>()
  
  private static let anchorQuery = EntityQuery(where: .has(AnchoringComponent.self))
  private static let systemOverlayQuery = EntityQuery(where: .has(BillboardComponent.self))
  
  private var anchorEntities: [AnchorEntity] = []
  private var previousFlipState: FlipState = .front
  private var previousIsClosed = false
  
  init(scene: RealityKit.Scene) { }
  
  mutating func update(context: SceneUpdateContext) {
    self.anchorEntities = context.entities(matching: Self.anchorQuery, updatingSystemWhen: .rendering)
      .compactMap { $0 as? AnchorEntity }
    
    let newFlipState = detectHandFlip(anchorEntities: anchorEntities)
    
    if newFlipState != previousFlipState {
      HandGestureSystem.handFlipPublisher.send(newFlipState)
      previousFlipState = newFlipState
    }
    
    let newIsClosed = areFingersTouching(anchorEntities: anchorEntities)
    
    if newIsClosed != previousIsClosed {
      HandGestureSystem.fingersClosePublisher.send(newIsClosed)
      previousIsClosed = newIsClosed
    }
    
    for entity in context.entities(matching: Self.systemOverlayQuery, updatingSystemWhen: .rendering) {
      if let transform = calculateCenterTransform(anchorEntities: anchorEntities) {
        entity.transform = Transform(matrix: transform)
      }
    }
  }
  
  private func detectHandFlip(anchorEntities: [AnchorEntity]) -> FlipState {
    guard anchorEntities.count >= 2 else { return .front }
    
    let indexFingerPosition = getWorldPosition(for: anchorEntities[0])
    let thumbPosition = getWorldPosition(for: anchorEntities[1])

    let thumbToIndex = thumbPosition.x - indexFingerPosition.x
    
    return thumbToIndex > 0 ? .front : .back
  }
  
  private func areFingersTouching(anchorEntities: [AnchorEntity]) -> Bool {
    guard anchorEntities.count >= 2 else { return false }
    
    let position1 = getWorldPosition(for: anchorEntities[0])
    let position2 = getWorldPosition(for: anchorEntities[1])
    
    let distance = simd_distance(position1, position2)
    
    return !distance.isZero && distance <= 0.03
  }

  private func calculateCenterTransform(anchorEntities: [AnchorEntity]) -> simd_float4x4? {
    guard anchorEntities.count >= 2 else { return nil }

    let position1 = getWorldPosition(for: anchorEntities[0])
    let position2 = getWorldPosition(for: anchorEntities[1])

    let centerPosition = (position1 + position2) * 0.5
    
    var transform = matrix_identity_float4x4
    transform.columns.3 = SIMD4<Float>(
      centerPosition.x,
      centerPosition.y + 0.03,
      centerPosition.z,
      1
    )
    return transform
  }
  
  private func getWorldPosition(for anchorEntity: AnchorEntity) -> SIMD3<Float> {
    anchorEntity.convert(position: anchorEntity.position, to: nil)
  }
}
