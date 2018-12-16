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
    float3 normal   [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 normal;
};

struct Material {
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};

struct Light {
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant Material material {
    .ambientColor = { 0.5, 0.3, 0.4 },
    .diffuseColor = { 0.5, 0.5, 0.5 },
    .specularColor = { 1.0, 1.0, 1.0 },
    .specularPower = 0.3
};

constant Light light {
    .direction = { -1.0, 2.0, 1.0 },
    .ambientColor = { 1.0, 1.0, 1.0 },
    .diffuseColor = { 1.0, 1.0, 1.0 },
    .specularColor = { 1.0, 1.0, 1.0 }
};

struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
    float3x3 normalMatrix;
};

vertex VertexOut vertex_main(VertexIn vertexIn [[stage_in]],
                             constant Uniforms &uniforms [[buffer(1)]])
{
    VertexOut vertexOut;
    vertexOut.position  = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vertexIn.position, 1);
    vertexOut.normal    = uniforms.normalMatrix * vertexIn.normal.xyz;
    
    return vertexOut;
}

fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]]) {
    
    float3 ambientTerm = light.ambientColor * material.ambientColor;
    
    float3 normal = normalize(fragmentIn.normal);
    float  diffuseIntensity = saturate(dot(normal, light.direction));
    float3 diffuseTerm = material.diffuseColor * light.diffuseColor * diffuseIntensity;
    
    return float4(ambientTerm + diffuseTerm, 1);
}

