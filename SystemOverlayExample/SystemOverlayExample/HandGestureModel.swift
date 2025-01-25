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

  var rightHandMiddleFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let rightHandMiddleFingerTip = latestHandTracking.right?.handSkeleton?.joint(.middleFingerTip),
          rightHandMiddleFingerTip.isTracked  else { return nil }
    return rightHandMiddleFingerTip.anchorFromJointTransform
  }
  var originFromRightHandMiddleFingerTipTransform: simd_float4x4? {
    guard let rightHandAnchorOriginFromAnchorTransfor = rightHandAnchorOriginFromAnchorTransform,
          let rightHandMiddleFingerTipAnchorFromJointTransform = rightHandMiddleFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(rightHandAnchorOriginFromAnchorTransfor, rightHandMiddleFingerTipAnchorFromJointTransform)
  }
  
  var rightHandIndexFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let rightHandIndexFingerTip = latestHandTracking.right?.handSkeleton?.joint(.indexFingerTip),
          rightHandIndexFingerTip.isTracked  else { return nil }
    return rightHandIndexFingerTip.anchorFromJointTransform
  }
  var originFromRightHandIndexFingerTipTransform: simd_float4x4? {
    guard let rightHandAnchorOriginFromAnchorTransfor = rightHandAnchorOriginFromAnchorTransform,
          let rightHandIndexFingerTipAnchorFromJointTransform = rightHandIndexFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(rightHandAnchorOriginFromAnchorTransfor, rightHandIndexFingerTipAnchorFromJointTransform)
  }

  var rightHandThumbFingerTipAnchorFromJointTransform: simd_float4x4? {
    guard let rightHandThumbFingerTip = latestHandTracking.right?.handSkeleton?.joint(.thumbTip),
          rightHandThumbFingerTip.isTracked  else { return nil }
    return rightHandThumbFingerTip.anchorFromJointTransform
  }
  var originFromRightHandThumbFingerTipTransform: simd_float4x4? {
    guard let rightHandAnchorOriginFromAnchorTransfor = rightHandAnchorOriginFromAnchorTransform,
          let rightHandThumbFingerTipAnchorFromJointTransform = rightHandThumbFingerTipAnchorFromJointTransform else { return nil }
    return matrix_multiply(rightHandAnchorOriginFromAnchorTransfor, rightHandThumbFingerTipAnchorFromJointTransform)
  }
  
  var rightHandFingerCenterTransform: simd_float4x4? {
    guard let originFromRightHandIndexFingerTipTransform = originFromRightHandIndexFingerTipTransform,
          let originFromRightHandMiddleFingerTipTransform = originFromRightHandMiddleFingerTipTransform,
          let originFromRightHandThumbFingerTipTransform = originFromRightHandThumbFingerTipTransform,
          let cameraTransform = headTransform else { return nil }

//    let position1 = originFromRightHandIndexFingerTipTransform.columns.3.xyz
    let position1 = originFromRightHandMiddleFingerTipTransform.columns.3.xyz
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

    // ここで「上に3cm」「奥に3cm」分の平行移動を追加
    var translationMatrix = matrix_identity_float4x4
    translationMatrix.columns.3.y = 0.03
    orientationMatrix = matrix_multiply(orientationMatrix, translationMatrix)
    
    return orientationMatrix
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
  
  func isRightHandFingersTouching() -> Bool {
    guard let indexTransform = originFromRightHandIndexFingerTipTransform,
          let middleTransform = originFromRightHandMiddleFingerTipTransform,
          let thumbTransform = originFromRightHandThumbFingerTipTransform else {
        return false
    }
//    let position1 = indexTransform.columns.3.xyz
    let position1 = thumbTransform.columns.3.xyz
    let position2 = middleTransform.columns.3.xyz
    let distance = simd_distance(position1, position2)
    print("distance:", distance)
    return distance <= 0.03
  }
}
