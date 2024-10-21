import ARKit

@MainActor
class HandGestureModel: ObservableObject, @unchecked Sendable {
  let session = ARKitSession()
  var handTracking = HandTrackingProvider()
  @Published var latestHandTracking: HandsUpdates = .init(left: nil, right: nil)
  var rightHandAnchorOriginFromAnchorTransform: simd_float4x4? {
    guard let rightHandAnchor = latestHandTracking.right, rightHandAnchor.isTracked else { return nil }
    return rightHandAnchor.originFromAnchorTransform
  }
  var rightHandIndexFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let rightHandIndexFingerTip = latestHandTracking.right?.handSkeleton?.joint(.indexFingerTip),
          rightHandIndexFingerTip.isTracked  else { return nil }
    return rightHandIndexFingerTip.anchorFromJointTransform
  }
  var rightHandMiddleFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let rightHandMiddleFingerTip = latestHandTracking.right?.handSkeleton?.joint(.middleFingerTip),
          rightHandMiddleFingerTip.isTracked  else { return nil }
    return rightHandMiddleFingerTip.anchorFromJointTransform
  }
  var originFromRightHandIndexFingerTipTransform: simd_float4x4? {
    guard let rightHandAnchorOriginFromAnchorTransfor = rightHandAnchorOriginFromAnchorTransform,
          let rightHandIndexFingerTipAnchorFromJointTransform = rightHandIndexFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(rightHandAnchorOriginFromAnchorTransfor, rightHandIndexFingerTipAnchorFromJointTransform)
  }
  var originFromRightHandMiddleFingerTipTransform: simd_float4x4? {
    guard let rightHandAnchorOriginFromAnchorTransfor = rightHandAnchorOriginFromAnchorTransform,
          let rightHandMiddleFingerTipAnchorFromJointTransform = rightHandMiddleFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(rightHandAnchorOriginFromAnchorTransfor, rightHandMiddleFingerTipAnchorFromJointTransform)
  }
  var rightHandFingerCenterTransform: simd_float4x4? {
    guard let originFromRightHandIndexFingerTipTransform = originFromRightHandIndexFingerTipTransform,
          let originFromRightHandMiddleFingerTipTransform = originFromRightHandMiddleFingerTipTransform else { return nil }
    let position1 = originFromRightHandIndexFingerTipTransform.columns.3.xyz
    let position2 = originFromRightHandMiddleFingerTipTransform.columns.3.xyz
    
    let centerPosition = (position1 + position2) * 0.5
    
    var centerMatrix = matrix_identity_float4x4
    centerMatrix.columns.3 = simd_float4(centerPosition, 1)
    
    return centerMatrix
  }

  var leftHandAnchorOriginFromAnchorTransform: simd_float4x4? {
    guard let leftHandAnchor = latestHandTracking.left, leftHandAnchor.isTracked else { return nil }
    return leftHandAnchor.originFromAnchorTransform
  }
  var leftHandIndexFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let leftHandIndexFingerTip = latestHandTracking.left?.handSkeleton?.joint(.indexFingerTip),
          leftHandIndexFingerTip.isTracked  else { return nil }
    return leftHandIndexFingerTip.anchorFromJointTransform
  }
  var leftHandMiddleFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let leftHandMiddleFingerTip = latestHandTracking.left?.handSkeleton?.joint(.middleFingerTip),
          leftHandMiddleFingerTip.isTracked  else { return nil }
    return leftHandMiddleFingerTip.anchorFromJointTransform
  }
  var originFromLeftHandIndexFingerTipTransform: simd_float4x4? {
    guard let leftHandAnchorOriginFromAnchorTransfor = leftHandAnchorOriginFromAnchorTransform,
          let leftHandIndexFingerTipAnchorFromJointTransform = leftHandIndexFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(leftHandAnchorOriginFromAnchorTransfor, leftHandIndexFingerTipAnchorFromJointTransform)
  }
  var originFromLeftHandMiddleFingerTipTransform: simd_float4x4? {
    guard let leftHandAnchorOriginFromAnchorTransfor = leftHandAnchorOriginFromAnchorTransform,
          let leftHandMiddleFingerTipAnchorFromJointTransform = leftHandMiddleFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(leftHandAnchorOriginFromAnchorTransfor, leftHandMiddleFingerTipAnchorFromJointTransform)
  }
  var leftHandFingerCenterTransform: simd_float4x4? {
    guard let originFromLeftHandIndexFingerTipTransform = originFromLeftHandIndexFingerTipTransform,
          let originFromLeftHandMiddleFingerTipTransform = originFromLeftHandMiddleFingerTipTransform else { return nil }
    let position1 = originFromLeftHandIndexFingerTipTransform.columns.3.xyz
    let position2 = originFromLeftHandMiddleFingerTipTransform.columns.3.xyz
    
    let centerPosition = (position1 + position2) * 0.5
    
    var centerMatrix = matrix_identity_float4x4
    centerMatrix.columns.3 = simd_float4(centerPosition, 1)
    
    return centerMatrix
  }
  
  struct HandsUpdates {
    var left: HandAnchor?
    var right: HandAnchor?
  }
  
  func start() async {
    do {
      if HandTrackingProvider.isSupported {
        print("ARKitSession starting.")
        try await session.run([handTracking])
      }
    } catch {
      print("ARKitSession error:", error)
    }
  }
  
  func publishHandTrackingUpdates() async {
    for await update in handTracking.anchorUpdates {
      switch update.event {
      case .updated:
        let anchor = update.anchor
        guard anchor.isTracked else { continue }
        
        if anchor.chirality == .left {
          latestHandTracking.left = anchor
        } else if anchor.chirality == .right {
          latestHandTracking.right = anchor
        }
      default:
        break
      }
    }
  }
  
  func monitorSessionEvents() async {
    for await event in session.events {
      switch event {
      case .authorizationChanged(let type, let status):
        if type == .handTracking && status != .allowed {
          // Stop the game, ask the user to grant hand tracking authorization again in Settings.
        }
      default:
        print("Session event \(event)")
      }
    }
  }
}
