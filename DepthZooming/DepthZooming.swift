//
//  FitZoomProtocol.swift
//  DepthZooming
//
//  Created by Jun Narumi on 2018/10/03.
//  Copyright © 2018 Jun Narumi. All rights reserved.
//

import SceneKit

/*!
 @abstract 視線に垂直で指定した点を通る面のサイズを変化させずに、画角を変化させる
 @param targetPoint 仮の基準座標 (実際の基準点は視線上の最近接点となる）
 @param targetFov 希望する画角（fovLimitでクランプされる）
 @param fovLimit 許容する画角の範囲。標準値は(1,90)
 */
func depthZooming(sceneView: SCNView,
                  targetPoint c: vector_float3,
                  targetFov newAng: CGFloat,
                  fovLimit limit: (lower: CGFloat, upper: CGFloat) ) {

    assert( limit.lower < limit.upper )
    assert( 0 < limit.lower && limit.lower < 180 )
    assert( 0 < limit.upper && limit.upper < 180 )

    var newAng = newAng
    if newAng < limit.lower {
        newAng = limit.lower
    }
    if newAng > limit.upper {
        newAng = limit.upper
    }
    guard let pointOfView = sceneView.pointOfView else {
        assert(false)
        return
    }
    guard let camera = pointOfView.camera else {
        assert(false)
        return
    }
    // orthographicへの切り替えを固定化することで、orthoからperspectiveへの復帰の計算を楽にしている
    // 矩形の中心点
    let mid = sceneView.bounds.mid
    // 画面真ん中をカメラの位置からzFarまで通る線分ab
    let a = pointOfView.simdPosition
    let b = vector_float3( sceneView.unprojectPoint( SCNVector3( mid.x, mid.y, 1 ) ) )
    // 算出した勝手な注視点
    let pos = closestPointWithLineSegment( point: c, lineSegment: (a, b) )
    let dist = distance( pos, a )

    let ang = camera.fieldOfView
    let cameraMove = newAng - ang

    if camera.usesOrthographicProjection && cameraMove > 0 {
        // 正投影で望遠方向に操作された場合、角度の下限値で投影に復帰
        let scale = camera.orthographicScale
        let newDist = rightTriangleDistance( halfRadian(degree: Double(limit.lower)), scale )
        let newPosition = normalize(b - a) * (dist - Float(newDist)) + a

        camera.fieldOfView = limit.lower
        pointOfView.simdPosition = newPosition
        camera.usesOrthographicProjection = false
        return
    } else if camera.usesOrthographicProjection && cameraMove < 0 {
        // 正投影で広角方向に操作された場合、更新を行わない
        return
    }

    let newDist: Double = distanceByAngleChange( halfRadian(degree: Double(newAng)), halfRadian(degree: Double(ang)), Double(dist) )
    let scale = rightTriangleHeight( halfRadian(degree: Double(newAng)), newDist )
    let newPosition = normalize(b - a) * (dist - Float(newDist)) + a

    camera.fieldOfView = newAng
    pointOfView.simdPosition = newPosition
    camera.orthographicScale = scale
    // 角度下限値で正投影に移行する
    camera.usesOrthographicProjection = newAng == limit.lower

}

private extension CGRect {
    var mid: CGPoint {
        return CGPoint( x: self.midX, y: self.midY )
    }
}

private func halfRadian( degree: Double ) -> Double {
    return degree * .pi / 180.0 * 0.5
}

private func rightTriangleDistance(_ angle: Double,_ height: Double ) -> Double
{
    return tan(.pi / 2.0 - angle) * height;
}

private func rightTriangleHeight(_ angle: Double,_ distance: Double ) -> Double
{
    return tan(angle) * distance;
}

// 角度、距離、高さのうち、高さを固定したまま角度を変化させた場合の距離を得る
private func distanceByAngleChange(_ newAngle: Double,_ oldAngle: Double,_ oldDistance: Double ) -> Double
{
    let commonHeight = rightTriangleHeight( oldAngle, oldDistance );
    return rightTriangleDistance( newAngle, commonHeight);
}

/*!
 @func closestPointWithLineSegment
 @abstract c点と線分abの最近接点
 */
private func closestPointWithLineSegment( point c: vector_float3, lineSegment seg: (a:vector_float3,b:vector_float3 ) ) -> vector_float3 {
    let ab = seg.b - seg.a
    var t = dot( c - seg.a, ab ) / dot( ab, ab )
    if t < 0.0 {
        t = 0.0
    }
    if t > 1.0 {
        t = 1.0
    }
    return seg.a + t * ab
}

