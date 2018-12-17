//
//  Renderer.swift
//  metal-teapot
//
//  Created by Blake Lockley on 11/12/18.
//  Copyright © 2018 Blake Lockley. All rights reserved.
//

import Metal
import MetalKit
import ModelIO

import simd

struct Uniforms {
    var modelViewMatrix: float4x4
    var projectionMatrix: float4x4
    var normalMatrix: float3x3
}

class Renderer: NSObject, MTKViewDelegate {
    
    let device: MTLDevice
    unowned let mtkView: MTKView
    
    // Resources
    private var meshes: [MTKMesh] = []
    private var vertexDescriptor: MTLVertexDescriptor!
    
    // Pipeline
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    
    // Unifroms
    private var time: Float = 0
    private var uniforms: Uniforms!
    
    init(device: MTLDevice, mtkView: MTKView) {
        self.device = device
        self.mtkView = mtkView
        
        self.commandQueue = device.makeCommandQueue()
        
        super.init()
        loadResources()
        buildPipeline()
    }
    
    func loadResources() {
        let modelURL = Bundle.main.url(forResource: "teapot", withExtension: "obj")
        
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 6)
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: modelURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
        
        do {
            (_, meshes) = try MTKMesh.newMeshes(asset: asset, device: device)
        } catch {
            fatalError("Unable to load meshes")
        }
        
        self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
    }
    
    func buildPipeline() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Unable to load default library")
        }
        
        let vertexFunction = library.makeFunction(name: "vertex_main")
        let fragmentFunction = library.makeFunction(name: "fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        do {
            self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create pipeline state")
        }
    }
    
    //MARK: MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // pass
    }
    
    func draw(in view: MTKView) {
        time += 1 / Float(view.preferredFramesPerSecond)
        let angle = -time
        
        let modelMatrix = float4x4(rotationAbout: float3(0, 1, 0), by: angle) * float4x4(scaleBy: 0.2)
        let viewMatrix = float4x4(translationBy: float3(0, -0.2, -2))
        
        let modelViewMatrix = viewMatrix * modelMatrix
        
        let aspectRatio = Float(mtkView.frame.size.width / mtkView.frame.size.height)
        let projectionMatrix = float4x4(perspectiveProjectionFov: Float.pi / 3, aspectRatio: aspectRatio, nearZ: 0.1, farZ: 100)
        
        let normalMatrix = modelViewMatrix.normalMatrix()
        
        uniforms = Uniforms(modelViewMatrix: modelViewMatrix, projectionMatrix: projectionMatrix, normalMatrix: normalMatrix)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        guard
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable else {
                fatalError("Could not retreive drawable")
        }
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        commandEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.size, index: 1)
        
        for mesh in meshes {
            let vertexBuffer = mesh.vertexBuffers.first!
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in mesh.submeshes {
                let indexBuffer = submesh.indexBuffer
                
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: indexBuffer.buffer,
                                                     indexBufferOffset: indexBuffer.offset)
            }
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
}
