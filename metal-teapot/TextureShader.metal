//
//  TextureShader.metal
//  Evolve
//
//  Created by Blake Lockley on 18/12/18.
//  Copyright © 2018 Blake Lockley. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position  [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};


struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
};

constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);

vertex VertexOut tex_vertex(VertexIn vertexIn [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    vertexOut.position  = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vertexIn.position, 1);
    vertexOut.texCoords = vertexIn.texCoords;
    
    return vertexOut;
}

fragment float4 tex_fragment(VertexOut fragmentIn [[stage_in]],
                              texture2d<float, access::sample> texture [[texture(0)]]) {
    
    return texture.sample(textureSampler, fragmentIn.texCoords);
}

