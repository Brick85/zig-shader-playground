#version 410 core
#define MAX_STEPS 100
#define MIN_DIST 0.0001
uniform vec2 u_FramebufferSize;
uniform float u_Time;
in vec4 v_Color;
out vec4 f_Color;

float map(float value, float min1, float max1, float min2, float max2) {
    float perc = (value - min1) / (max1 - min1);
    float ret = perc * (max2 - min2) + min2;
    ret = clamp(ret, min2, max2);
    return ret;
}

float distToSphere(vec3 pos, vec4 sphere) {
    return length(pos - sphere.xyz) - sphere.w;
}

float distToGround(vec3 pos, float ground) {
    return pos.y - ground;
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

    vec3 cam = vec3(0., 0., 1.);
    vec3 vp = vec3(uv, 0.);
    vec3 ray = normalize(vp - cam);
    
    vec4 sphere = vec4(0., 0., -3., 1.);
    vec4 sphere2 = vec4(1.5, -0.5, -4., 0.5);

    vec3 pos = cam;
    for (int i = 0; i < MAX_STEPS; i++) {
        float dist;
        dist = distToGround(pos, -1.0);
        dist = min(dist, distToSphere(pos, sphere));
        dist = min(dist, distToSphere(pos, sphere2));
        if(dist < MIN_DIST) break;
        pos += ray * dist;
    }
    color = map(length(pos), 8., 1., 0., 1.);

    vec4 fcolor = vec4(color);
    // fcolor.r = uv.x+0.5;
    // fcolor.g = uv.y+0.5;
    f_Color = vec4(fcolor);
}
