//
//  MetalView.swift
//  ComplexLogistic
//
//  Created by Amanda Chaudhary on 2/26/22.
//

import SwiftUI
import MetalKit
import Accelerate
import simd

internal struct ViewParams {
  let minimumReal: Float
  let maximumImaginary: Float
  let horizontalStride: Float
  let verticalStride: Float
}

let xdefaultLowerLeft = simd_float2(x: -2, y: -2)
let xdefaultUpperRight = simd_float2(x: 4, y: 2)

let positions: [simd_float4] = [
  simd_float4(-1.0, 1.0, 0.0, 1.0),
  simd_float4(1.0, 1.0, 0.0, 1.0),
  simd_float4(-1.0, -1.0, 0.0, 1.0),
  simd_float4(1.0, 1.0, 0.0, 1.0),
  simd_float4(1.0, -1.0, 0.0, 1.0),
  simd_float4(-1.0, -1.0, 0.0, 1.0)
]

let shaders = """
#include <metal_stdlib>
using namespace metal;

#define product(a, b) float2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x)

struct VertexOut {
  float4 position [[position]];
};

[[vertex]] VertexOut
vertex_main(
  device const float4 * const positionList [[buffer(0)]],
  const uint vertexId [[vertex_id]]
) {
  VertexOut out {
    .position = positionList[vertexId],
  };
  return out;
}

struct ViewParams {
  float minimumReal;
  float maximumImaginary;
  float horizontalStride;
  float verticalStride;
};

[[fragment]] float4
fragment_main(
  const VertexOut in [[stage_in]],
  constant ViewParams &viewParams [[buffer(1)]]
) {
  const float2 a = float2(
    viewParams.minimumReal + in.position.x * viewParams.horizontalStride,
    viewParams.maximumImaginary - in.position.y * viewParams.verticalStride
  );

  float2 z = float2(0.5, 0.0);
  const uint maxIterations = 10000;
  uint i = 0;

  while (i < maxIterations) {
    float2 zSquared = float2(z.x*z.x - z.y*z.y, z.x*z.y + z.y*z.x);
    z.x = z.x - zSquared.x;
    z.y = z.y - zSquared.y;

    z = product(a,z);

    ++i;
    if ((z.x*z.x + z.y*z.y) > 1.0f) {
      break;
    }
  }

  if (i >= maxIterations) {
     return float4(0, 0, 0, 1);
  } else {
     return float4(1, 1, 1, 1);
  }
}
"""

internal class ExtendedMetalView : MTKView {
    
    var mouseUpHandler : (NSEvent)->() = {_ in }
    var rightMouseUpHandler : (NSEvent)->() = {_ in }
  
    
    override func mouseUp(with event: NSEvent) {
        mouseUpHandler(event)
    }
    
    override func rightMouseUp(with event: NSEvent) {
        rightMouseUpHandler(event)
    }
}


struct MetalView : NSViewRepresentable {

    
    typealias NSViewType = ExtendedMetalView
    
    private static let frame = CGRect(x: 0, y: 0, width: 1200, height: 800)

    private static let device : MTLDevice = {
        guard let _device = MTLCreateSystemDefaultDevice() else {
          fatalError("Unable to access a GPU.")
        }
        return _device
    }()
    
    @State private var lowerLeft = defaultLowerLeft
    @State private var upperRight = defaultUpperRight
    @State var viewParams  = ViewParams(
        minimumReal: defaultLowerLeft.x,
        maximumImaginary: defaultUpperRight.y,
        horizontalStride: (defaultUpperRight.x - defaultLowerLeft.x) / simd_float1(MetalView.frame.width),
        verticalStride: (defaultUpperRight.y - defaultLowerLeft.y) / simd_float1(MetalView.frame.height)
      )
    

    let metalView = { ExtendedMetalView(frame: frame, device: MetalView.device) }()
    
    
    func makeNSView(context: Context) -> ExtendedMetalView {
        metalView.mouseUpHandler = self.mouseUp
        metalView.rightMouseUpHandler = self.rightMouseUp
        return metalView
    }
    
    func updateNSView(_: Self.NSViewType, context: Self.Context) {
    }
    
    func update () {
        viewParams  = ViewParams(
            minimumReal: lowerLeft.x,
            maximumImaginary: upperRight.y,
            horizontalStride: (upperRight.x - lowerLeft.x) / simd_float1(MetalView.frame.width),
            verticalStride: (upperRight.y - lowerLeft.y) / simd_float1(MetalView.frame.height)
        )
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let library = try! MetalView.device.makeLibrary(source: shaders, options: nil)
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction

        let pipelineState = try! MetalView.device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        guard let commandQueue = MetalView.device.makeCommandQueue(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let descriptor = metalView.currentRenderPassDescriptor,
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let drawable = metalView.currentDrawable else {
          fatalError("Problem setting up to draw a frame.")
        }

        commandEncoder.setRenderPipelineState(pipelineState)

        let positionLength = MemoryLayout<simd_float4>.stride * positions.count
        let positionBuffer = MetalView.device.makeBuffer(bytes: positions, length: positionLength, options: [])!
        commandEncoder.setVertexBuffer(positionBuffer, offset: 0, index: 0)
        commandEncoder.setFragmentBytes(&viewParams, length: MemoryLayout<ViewParams>.stride, index: 1)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: positions.count)

        commandEncoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
        

    }
    
    func mouseUp(event : NSEvent) {
        let location = event.locationInWindow
        let point = metalView.convert(location, to: nil)
        let width = metalView.frame.width
        let height = metalView.frame.height
        
        print (point)
        
        let x = lowerLeft.x + (upperRight.x - lowerLeft.x) * simd_float1(point.x / width)
        let y = lowerLeft.y + (upperRight.y - lowerLeft.y) * simd_float1(point.y / height)

        print (x,y)
        
        let dx = 0.25 * (upperRight.x - lowerLeft.x)
        let dy = 0.25 * (upperRight.y - lowerLeft.y)
        
        print (dx,dy)
        
        lowerLeft = simd_float2(x: x - dx, y: y - dy)
        upperRight = simd_float2(x : x + dx, y: y + dy)
        
        print ("LL: ",lowerLeft)
        print ("UR: ",upperRight)
        update()
    }
    
    func rightMouseUp(event : NSEvent) {
        let location = event.locationInWindow
        let point = metalView.convert(location, to: nil)
        let width = metalView.frame.width
        let height = metalView.frame.height
        
        let x = lowerLeft.x + (upperRight.x - lowerLeft.x) * Float(point.x / width)
        let y = lowerLeft.y + (upperRight.y - lowerLeft.y) * Float(point.y / height)

        let dx = (upperRight.x - lowerLeft.x)
        let dy = (upperRight.y - lowerLeft.y)
        lowerLeft = simd_float2(x: x - dx, y: y - dy)
        upperRight = simd_float2(x : x + dx, y: y + dy)
        update()
    }
}



