#version 410 core
#define MAX_STEPS 1000
#define MIN_DIST 0.0001
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

struct ObjectPoint {
    Material material;
    float distance;
};

Sphere[3] spheres;
Object[4] objects;

float map(float value, float min1, float max1, float min2, float max2) {
    float perc = (value - min1) / (max1 - min1);
    float ret = perc * (max2 - min2) + min2;
    ret = clamp(ret, min2, max2);
    return ret;
}

ObjectPoint distToSphere(vec3 ray, vec3 pos, Object obj) {
    Sphere sphere = spheres[obj.objectTypeIndex];
    bool found = false;
    for (int i = 0; i < MAX_STEPS; i++) {
        float dist = length(pos - obj.position) - (sphere.radius);
        if (dist < MIN_DIST) {
            found = true;
            break;
        }
        pos += ray * dist;
    }
    float ret = 0.;
    if (found) {
        ret = length(pos);
    }
    return ObjectPoint(obj.material, ret);
    // return ObjectPoint(obj.material, pos - obj.position);
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
    spheres[1] = Sphere(1.0);
    spheres[2] = Sphere(0.3);

    float x = sin(u_Time) / 4. + 0.9;
    objects[1] = Object(
            vec3(-x, 0, -3.0),
            Material(Color(1, 0, 0)),
            0,
            true,
            false
        );

    objects[2] = Object(
            // vec3(1.5, -0.5, -4.0),
            vec3(x, 0., -3.0),
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

    vec3 test = vec3(sin(u_Time / 3), cos(u_Time / 7.) * 0.5, 0.0);
    test = vec3(0.0, 0.0, 0.0);
    vec3 cam = vec3(0., 0., 1.);
    vec3 vp = vec3(uv, 0.0);

    vec3 ray = normalize(vp - cam);
    vec3 pos = cam + test;

    Color obj_color = ambient;

    // ObjectPoint objPoint;
    // for (int j = 0; j < 4; j++) {
    //     Object obj = objects[j];
    //     if (obj.isGround) {
    //     } else if (obj.isSphere) {
    //         objPoint = distToSphere(pos, obj);
    //     }
    // }
    ObjectPoint objPoint1 = distToSphere(ray, pos, objects[1]);
    ObjectPoint objPoint2 = distToSphere(ray, pos, objects[2]);

    obj_color = Color(0.0);
    float distance = 10000.0;
    if (objPoint1.distance > 0. && objPoint2.distance > 0.) {
        obj_color = Color(1.0);
        if (objPoint1.distance - 0.1 < objPoint2.distance && objPoint1.distance > objPoint2.distance) {
            obj_color = Color(1.);
            distance = objPoint2.distance;
        } else if (objPoint1.distance < objPoint2.distance) {
            obj_color = objPoint1.material.color;
            distance = objPoint1.distance;
        } else {
            obj_color = objPoint2.material.color;
            distance = objPoint2.distance;
        }
        // if (objPoint1.distance - 0.0001 < objPoint2.distance && objPoint1.distance > objPoint2.distance) {
        // } else if (objPoint2.distance < objPoint1.distance) {
        //     obj_color = objPoint1.material.color;
        // } else {
        //     obj_color = objPoint2.material.color;
        // }
    } else if (objPoint1.distance > 0.) {
        obj_color += objPoint1.material.color;
        distance = objPoint1.distance;
    } else if (objPoint2.distance > 0.) {
        obj_color += objPoint2.material.color;
        distance = objPoint2.distance;
    }

    Color color;
    // float depth = map(length(pos), 8., 2., 0., 1.);
    float depth = map(distance, 4., 2., 0., 1.);
    color = obj_color;
    color = color * (depth);
    // color = Color(depth);

    f_Color = vec4(color, 1.0);
}
