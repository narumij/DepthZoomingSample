//
//  ViewController.swift
//  DepthZooming
//
//  Created by Jun Narumi on 2018/10/03.
//  Copyright © 2018 Jun Narumi. All rights reserved.
//

import SceneKit

class ViewController: NSViewController {

    @IBOutlet var sceneView: SCNView!

    var crossGeometry: SCNGeometry {
        let geoVec = [(-1.0,   0,   0),( 1.0,   0,   0),
                      (   0,-1.0,   0),(   0, 1.0,   0),
                      (   0,   0,-1.0),(   0,   0, 1.0),
                      ]
            .map{ vector_float3( $0.0, $0.1, $0.2 ) }
        let dg = Data(bytes: geoVec,
                      count: MemoryLayout<SCNVector3>.size * geoVec.count )
        let geo = SCNGeometrySource(data: dg,
                                    semantic: .vertex,
                                    vectorCount: geoVec.count,
                                    usesFloatComponents: true,
                                    componentsPerVector: 3,
                                    bytesPerComponent: MemoryLayout<Float>.size,
                                    dataOffset: 0,
                                    dataStride: MemoryLayout<vector_float3>.size)
        let ele = SCNGeometryElement(indices: [0,1,2,3,4,5] as [UInt16],
                                     primitiveType: .line )
        let g = SCNGeometry(sources: [geo],
                            elements: [ele])
        g.firstMaterial?.emission.contents = NSColor.white
        return g
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.showsStatistics = true
        let scene = SCNScene()
        let rootNode = scene.rootNode
        func box(_ pos: vector_float3 ) -> SCNNode {
            let boxGeo = SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0.03)
            let boxNode = SCNNode(geometry: boxGeo)
            boxNode.simdPosition = pos
            return boxNode
        }
        for p: (x:Float,y:Float,z:Float) in [
            (0,0,0), (1,1,1), (-1,1,1), (1,-1,1),
            (-1,-1,1), (1,1,-1), (-1,1,-1), (1,-1,-1), (-1,-1,-1),
            (-1,0,0), (1,0,0), (0,-1,0), (0,1,0), (0,0,-1), (0,0,1) ]
        {
            rootNode.addChildNode( box( vector_float3( p.x, p.y, p.z ) ) )
        }
        let camNode = SCNNode()
        let cam = SCNCamera()
        cam.automaticallyAdjustsZRange = true
        camNode.camera = cam
        camNode.localTranslate(by:  SCNVector3( x: 0, y: 0, z: 3 ) )
        rootNode.addChildNode(camNode)
        rootNode.addChildNode(SCNNode(geometry: crossGeometry))
        sceneView.scene = scene
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func depthZoomingGesture(_ sender: NSPanGestureRecognizer? ) {
        let y = (sender?.translation(in: sceneView).y ?? 0) * -0.01
        #if true
        let target = vector_float3( sceneView.defaultCameraController.target )
        #else
        let target = vector_float3(0)
        #endif
        depthZooming(sceneView: sceneView,
                     targetPoint: target,
                     targetFov: (sceneView.pointOfView?.camera?.fieldOfView).map{ $0 + y } ?? 45,
                     fovLimit: ( 2, 60 ) )

    }

}

