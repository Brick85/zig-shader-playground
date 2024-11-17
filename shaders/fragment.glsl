#version 410 core
#define Color vec3
#define MAX_DISTANCE 100
#define SURFACE 0.01
#define MAX_STEPS 1000

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

float smoothMin(float a, float b) {
    float q = 2.0;
    float t = max(0, min(1, ((b - a) / q) + 0.5));
    float s = t * (1 - t) * q;
    return (a * t) + (b * (1 - t)) - (s / 2);
}

float getSdfDistanceSphere(vec3 pos, vec3 spherePosition, float radius) {
    float distance = length(spherePosition - pos) - radius;
    return distance;
}

float getSdfDistanceGround(vec3 pos) {
    float height = 0;
    return pos.y - height;
}

float getSdfDistance(vec3 pos) {
    float ground = getSdfDistanceGround(pos);
    float x = ((sin(u_Time) + 1.) / 2.) + 0.5;
    float sphereDistance = getSdfDistanceSphere(pos, vec3(x, 1.0, 4), 1.0);
    float sphereDistance2 = getSdfDistanceSphere(pos, vec3(-x, 1.0, 4), 1.0);
    float sphereTotalDistance = smoothMin(sphereDistance, sphereDistance2);
    float distance = smoothMin(ground, sphereTotalDistance);
    return distance;
}

float doRayMarch(vec3 cam, vec3 ray) {
    float totalDistance = 0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 tpos = cam + ray * totalDistance;
        float distance = getSdfDistance(tpos);
        totalDistance += distance;
        if (totalDistance < SURFACE || totalDistance > MAX_DISTANCE) {
            break;
        }
    }
    return totalDistance;
}

vec3 getNormalOfPoint(vec3 point) {
    vec2 dat = vec2(0.0, 0.001);
    float distance = getSdfDistance(point);
    vec3 point2 = distance - vec3(
                getSdfDistance(point - dat.yxx),
                getSdfDistance(point - dat.xyx),
                getSdfDistance(point - dat.xxy)
            );
    // vec3 point2 = vec3(
    //         getSdfDistance(point + dat.yxx) - getSdfDistance(point - dat.yxx),
    //         getSdfDistance(point + dat.xyx) - getSdfDistance(point - dat.xyx),
    //         getSdfDistance(point + dat.xxy) - getSdfDistance(point - dat.xxy)
    //     );
    return normalize(point2);
}

Color getColorOfPoint(vec3 point) {
    // float distance = getSdfDistance(point);
    // if (distance >= 1.0) return vec3(0);
    // else return vec3(1, 0, 0);
    Color color;
    float x = sin(u_Time * 0.5);
    float y = cos(u_Time * 0.5);
    vec3 light = vec3(x * 10, 10, y * 10);
    vec3 normal = getNormalOfPoint(point);
    vec3 normToLight = normalize(light - point);
    float intensity = dot(normToLight, normal);
    intensity = clamp(intensity, 0., 1.);

    vec3 shadowPoint = point + normal * SURFACE * 10;
    float distanceToLight = length(light - shadowPoint);
    float distanceToLightRM = doRayMarch(shadowPoint, normToLight);

    if (distanceToLight > distanceToLightRM) {
        intensity *= 0.2;
    }
    if (distanceToLight > MAX_DISTANCE) {
        intensity = 0;
    }

    color = vec3(intensity);

    return color;
}

Color getSdfColor(vec3 cam, vec3 ray) {
    float distance = doRayMarch(cam, ray);
    vec3 point = cam + ray * distance;

    Color color = getColorOfPoint(point);
    // float depth = map(distance, 12., 2., 0., 1.);

    return color;
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

    vec3 cam = vec3(0., 1., 0.);
    vec3 ray = normalize(vec3(uv, 1.0));

    Color color = getSdfColor(cam, ray);

    f_Color = vec4(color, 1.0);
}
