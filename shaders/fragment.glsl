#version 410 core
uniform vec2 u_FramebufferSize;
uniform float u_Time;
in vec4 v_Color;
out vec4 f_Color;
void main() {
    vec2 uv = gl_FragCoord.xy / u_FramebufferSize;
    vec4 color = v_Color;
    color.r = sin(u_Time) * 0.5 + 0.5;
    color.b = uv.x;
    color.g = uv.y;
    f_Color = color;
}
