import ARKit
import QuartzCore

@MainActor
class HandGestureModel: ObservableObject, @unchecked Sendable {
  let session = ARKitSession()
  var handTracking = HandTrackingProvider()
  let worldTracking = WorldTrackingProvider()
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
  var rightHandThumbFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let rightHandThumbFingerTip = latestHandTracking.right?.handSkeleton?.joint(.thumbTip),
          rightHandThumbFingerTip.isTracked  else { return nil }
    return rightHandThumbFingerTip.anchorFromJointTransform
  }
  var originFromRightHandIndexFingerTipTransform: simd_float4x4? {
    guard let rightHandAnchorOriginFromAnchorTransfor = rightHandAnchorOriginFromAnchorTransform,
          let rightHandIndexFingerTipAnchorFromJointTransform = rightHandIndexFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(rightHandAnchorOriginFromAnchorTransfor, rightHandIndexFingerTipAnchorFromJointTransform)
  }
  var originFromRightHandThumbFingerTipTransform: simd_float4x4? {
    guard let rightHandAnchorOriginFromAnchorTransfor = rightHandAnchorOriginFromAnchorTransform,
          let rightHandThumbFingerTipAnchorFromJointTransform = rightHandThumbFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(rightHandAnchorOriginFromAnchorTransfor, rightHandThumbFingerTipAnchorFromJointTransform)
  }
  var rightHandFingerCenterTransform: simd_float4x4? {
      guard let originFromRightHandIndexFingerTipTransform = originFromRightHandIndexFingerTipTransform,
            let originFromRightHandThumbFingerTipTransform = originFromRightHandThumbFingerTipTransform,
            let cameraTransform = headTransform else { return nil }

      let position1 = originFromRightHandIndexFingerTipTransform.columns.3.xyz
      let position2 = originFromRightHandThumbFingerTipTransform.columns.3.xyz

      let centerPosition = (position1 + position2) * 0.5

      // カメラ（ユーザーの視線）方向を取得
      let cameraPosition = cameraTransform.columns.3.xyz

      // 中心点からカメラ方向へのベクトルを求める
      let forward = simd_normalize(cameraPosition - centerPosition)
      let up = SIMD3<Float>(0, 1, 0)
      let right = simd_normalize(simd_cross(up, forward))
      let correctedUp = simd_cross(forward, right)

      // 回転行列を構築
      var orientationMatrix = matrix_identity_float4x4
      orientationMatrix.columns.0 = simd_float4(right, 0)
      orientationMatrix.columns.1 = simd_float4(correctedUp, 0)
      orientationMatrix.columns.2 = simd_float4(forward, 0)
      orientationMatrix.columns.3 = simd_float4(centerPosition, 1)

      return orientationMatrix
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
  var headTransform: simd_float4x4? {
    guard let anchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return nil }
    return anchor.originFromAnchorTransform
  }
  
  struct HandsUpdates {
    var left: HandAnchor?
    var right: HandAnchor?
  }
  
  func start() async {
    do {
      if HandTrackingProvider.isSupported {
        print("ARKitSession starting.")
        try await session.run([worldTracking, handTracking])
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
