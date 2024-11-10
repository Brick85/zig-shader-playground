#version 410 core
uniform vec2 u_FramebufferSize;
uniform float u_Time;
in vec4 a_Position;
in vec4 a_Color;
out vec4 v_Color;
void main() {
    gl_Position = a_Position;
    v_Color = a_Color;
}
