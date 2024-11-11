#version 410 core
#define SMOOTH 0.001
uniform vec2 u_FramebufferSize;
uniform float u_Time;
in vec4 v_Color;
out vec4 f_Color;

float circle(vec2 uv, vec2 pos, float radius) {
    float d = length(uv - pos);
    return smoothstep(radius+SMOOTH, radius-SMOOTH, d);
}

float rectangle(vec2 uv, vec2 pos, vec2 size) {
    vec2 d = uv - pos;
    float draw_x = smoothstep(-SMOOTH, SMOOTH, d.x) - smoothstep(-SMOOTH, SMOOTH, d.x-size.x);
    float draw_y = smoothstep(-SMOOTH, SMOOTH, d.y) - smoothstep(-SMOOTH, SMOOTH, d.y-size.y);
    return draw_x * draw_y;
}

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

    float color = 0.;

    color += circle(uv, vec2(-0.1, -0.3), 0.13);
    color += circle(uv, vec2( 0.1, -0.3), 0.13);
    color += circle(uv, vec2( 0.0,  0.3), 0.11);
    color += rectangle(uv, vec2(-0.1, -0.3), vec2(0.2, 0.6));

    color = clamp(color, 0., 1.);

    vec4 fcolor = vec4(color);
    fcolor.r *= (sin(u_Time*7)+1.0)/2.0;
    fcolor.g *= (cos(u_Time)+1.0)/2.0;
    f_Color = vec4(fcolor);
}
