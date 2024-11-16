#version 410 core
#define MAX_STEPS 1000
#define MIN_DIST 0.001
#define Color vec3

uniform vec2 u_FramebufferSize;
uniform float u_Time;
in vec4 v_Color;
out vec4 f_Color;

struct Material {
    Color color;
};

struct Light {
    vec3 position;
    Color color;
};

struct Sphere {
    float radius;
};

struct Object {
    vec3 position;
    Material material;
    int objectTypeIndex;
    bool isSphere;
    bool isGround;
};

Sphere[3] spheres;
Object[4] objects;

float map(float value, float min1, float max1, float min2, float max2) {
    float perc = (value - min1) / (max1 - min1);
    float ret = perc * (max2 - min2) + min2;
    ret = clamp(ret, min2, max2);
    return ret;
}

float distToSphere(vec3 pos, Object obj) {
    Sphere sphere = spheres[obj.objectTypeIndex];
    return length(pos - obj.position) - (sphere.radius);
}

float distToGround(vec3 pos, Object obj) {
    float ground = obj.position.x;
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

    objects[0] = Object(
            vec3(-1.0, 0, 0),
            Material(Color(0.5, 0.5, 0.5)),
            0,
            false,
            true
        );

    Color ambient = Color(.0);

    spheres[0] = Sphere(1.0);
    spheres[1] = Sphere(0.5);
    spheres[2] = Sphere(0.3);

    objects[1] = Object(
            vec3(0, 0, -3.0),
            Material(Color(1, 0, 0)),
            0,
            true,
            false
        );

    objects[2] = Object(
            vec3(1.5, -0.5, -4.0),
            Material(Color(0, 1, 0)),
            1,
            true,
            false
        );
    objects[3] = Object(
            vec3(-1.5, -0.7, -4.0),
            Material(Color(0, 0, 1)),
            2,
            true,
            false
        );

    vec3 test = vec3(sin(u_Time), cos(u_Time / 2.) * 0.9, 0.0);
    vec3 cam = vec3(0., 0., 1.);
    vec3 vp = vec3(uv, 0.0);

    vec3 ray = normalize(vp - cam);
    vec3 pos = cam + test;

    Color obj_color = ambient;
    for (int i = 0; i < MAX_STEPS; i++) {
        float dist = 1.;

        for (int j = 0; j < 4; j++) {
            Object obj = objects[j];
            float objDist = 0.;
            if (obj.isGround) {
                objDist = distToGround(pos, obj);
            } else if (obj.isSphere) {
                objDist = distToSphere(pos, obj);
            }
            if (objDist < dist) {
                dist = objDist;
                obj_color = obj.material.color;
            }
        }

        if (dist < MIN_DIST) break;
        pos += ray * dist;
        obj_color = ambient;
    }
    Color color;
    float depth = map(length(pos), 8., 2., 0., 1.);
    color = obj_color * depth;

    f_Color = vec4(color, 1.0);
}
