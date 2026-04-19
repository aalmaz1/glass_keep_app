#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    // Animate the grain using time
    float noise = random(uv + fract(uTime));
    
    // Very subtle white noise
    fragColor = vec4(vec3(1.0), noise * 0.04);
}
