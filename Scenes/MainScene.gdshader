shader_type canvas_item;

uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float size : hint_range(0.01, 1.0) = 0.2;
uniform float pause : hint_range(0.0, 5.0) = 0.5;

void fragment() {
    vec4 text_color = COLOR;

    float shine_pos = mod(TIME * speed, 2.0 + pause) - 0.5;

    float center = shine_pos + size / 2.0;
    float dist = abs((UV.x - UV.y) - center);

    float shine = 1.0 - smoothstep(0.0, size / 2.0, dist);

    vec3 shine_color = vec3(1.0, 1.0, 1.0);
    vec3 final_color = mix(text_color.rgb, shine_color, shine);

    COLOR = vec4(final_color, text_color.a);
}