#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uStrength;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Distort UV based on distance from center for a more natural look
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    float amount = uStrength * 0.02 * dist;
    
    float r = texture(uTexture, uv + vec2(amount, 0.0)).r;
    float g = texture(uTexture, uv).g;
    float b = texture(uTexture, uv - vec2(amount, 0.0)).b;
    
    // Get the original alpha from the texture
    float alpha = texture(uTexture, uv).a;
    
    fragColor = vec4(r, g, b, alpha);
}
