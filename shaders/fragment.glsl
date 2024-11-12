#version 410 core
#define MAX_STEPS 1000
#define MIN_DIST 0.001
#define Color vec3

uniform vec2 u_FramebufferSize;
uniform float u_Time;
in vec4 v_Color;
out vec4 f_Color;

struct Light {
    vec3 position;
};

struct Sphere {
    vec3 position;
    float radius;
    Color color;
};

struct Ground {
    float height;
    Color color;
};


float map(float value, float min1, float max1, float min2, float max2) {
    float perc = (value - min1) / (max1 - min1);
    float ret = perc * (max2 - min2) + min2;
    ret = clamp(ret, min2, max2);
    return ret;
}

float distToSphere(vec3 pos, Sphere sphere) {
    return length(pos - sphere.position) - sphere.radius;
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

    Color ambient = Color(.0);

    Light baseLight;
    baseLight.position = vec3(-2.0, 10.0, -2.0);

    Ground ground;
    ground.height = -1.0;
    ground.color = Color(0.5, 0.5, 0.5);

    Sphere[3] spheres;
    spheres[0] = Sphere(vec3(0.0, 0.0, -3.0), 1.0, Color(1., sin(u_Time), 0.));
    spheres[1] = Sphere(vec3(1.5, -0.5, -4.0), 0.5, Color(0., 1., cos(u_Time*3.)));
    spheres[2] = Sphere(vec3(-1.5, -0.7, -4.0), 0.3, Color(sin(u_Time*10.), 0., 1.));


    vec3 cam = vec3(0., 0., 1.);
    vec3 vp = vec3(uv, 0.);
    vec3 ray = normalize(vp - cam);
    

    vec3 pos = cam;
    Color obj_color = ambient;
    for (int i = 0; i < MAX_STEPS; i++) {
        float dist = 1.;
        
        for (int j = 0; j < 3; j++) {
            float objDist = distToSphere(pos, spheres[j]);
            if (objDist < dist) {
                dist = objDist;
                obj_color = spheres[j].color;
            }
        }
        float objDist = distToGround(pos, ground.height);
        if (objDist < dist) {
            dist = objDist;
            obj_color = ground.color;
        }

        if(dist < MIN_DIST) break;
        pos += ray * dist;
        obj_color = ambient;
    }
    Color color;
    float depth = map(length(pos), 8., 2., 0., 1.);
    color = obj_color * depth;
    // color = Color();

    f_Color = vec4(color, 1.0);
}
