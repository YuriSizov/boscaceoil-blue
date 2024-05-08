/***************************************************/
/* Part of Bosca Ceoil Blue                        */
/* Copyright (c) 2024 Yuri Sizov and contributors  */
/* Provided under MIT                              */
/***************************************************/

shader_type canvas_item;

uniform vec4 base_color : source_color;
uniform vec4 stripe_color : source_color;

uniform float speed : hint_range(0.0, 100.0, 1.0) = 6;
uniform float speed_factor : hint_range(-1.0, 1.0, 1.0) = -1.0;
uniform float frequency : hint_range(1.0, 100.0, 0.25) = 50.0;
uniform float ratio : hint_range(-1.0, 1.0, 0.1) = 0.0;
uniform float angle : hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
	vec3 pixel = base_color.rgb;

	float base_value = speed * speed_factor * TIME + frequency * UV.x * angle + frequency * UV.y * (1.0 - angle);
	pixel = mix(pixel, stripe_color.rgb, step(sin(abs(base_value)), ratio));

	COLOR = vec4(pixel, 1.0);
}
