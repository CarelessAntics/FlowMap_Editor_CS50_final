# pragma language glsl3

#define FLOW_RATE .2
#define STRENGTH .2

uniform vec2 iResolution;
uniform float iTime;
uniform Image vectorMap;

vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords )
{
    vec2 uv = screen_coords / iResolution;
    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);

    vec4 vectors = Texel(vectorMap, texture_coords);
    vec2 flow = ((vectors.rg * 2. - 1.) * - 1.) * STRENGTH;
    
    vec2 fUv1 = texture_coords + fract(iTime * FLOW_RATE) * flow; 
    vec2 fUv2 = texture_coords + fract(iTime * FLOW_RATE + .5) * flow;

    vec4 texture1 = Texel(tex, fUv1);
    vec4 texture2 = Texel(tex, fUv2);
    
    vec4 textureCol = mix(texture1, texture2, abs(fract(iTime * FLOW_RATE) - .5) * 2.);

    return textureCol;
}
