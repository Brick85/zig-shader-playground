#version 410 core
uniform vec2 u_FramebufferSize;
uniform float u_Time;
in vec4 v_Color;
out vec4 f_Color;
void main() {
    vec2 uv = gl_FragCoord.xy;
    if (u_FramebufferSize.x > u_FramebufferSize.y) {
        uv.xy /= u_FramebufferSize.y;
        uv.x -= 0.5 * (u_FramebufferSize.x / u_FramebufferSize.y);
        uv.y -= 0.5;
    } else {
        uv.xy /= u_FramebufferSize.x;
        uv.x -= 0.5;
        uv.y -= 0.5 * (u_FramebufferSize.y / u_FramebufferSize.x);
    }
    vec4 color = v_Color;
    color.r = sin(u_Time) * 0.5 + 0.5;
    color.b = uv.x;
    color.g = uv.y;
    float d = length(uv);
    color.r = smoothstep(0.498, 0.502, d) * color.r;
    f_Color = color;
}
