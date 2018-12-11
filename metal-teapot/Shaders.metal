//
//  Shaders.metal
//  metal-teapot
//
//  Created by Blake Lockley on 11/12/18.
//  Copyright © 2018 Blake Lockley. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
};

struct VertexOut {
    float4 position [[position]];
};

struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut vertex_main(VertexIn vertexIn [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    vertexOut.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vertexIn.position, 1);
    return vertexOut;
}

fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]]) {
    return float4(0, 1, 0.5, 1);
}

