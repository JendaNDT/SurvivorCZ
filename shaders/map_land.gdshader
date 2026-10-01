// Textura trávy pro kraje na mapě: barva kraje z vrcholů + šum a trsy trávy.
shader_type canvas_item;

varying vec2 p;

void vertex() {
	p = VERTEX;
}

float hash(vec2 q) {
	q = mod(q, 256.0);
	return fract(sin(dot(q, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 q) {
	vec2 i = floor(q);
	vec2 f = fract(q);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec3 c = COLOR.rgb;
	float n = noise(p * 0.035) * 0.6 + noise(p * 0.12) * 0.4;
	c *= 0.9 + 0.18 * n;
	vec2 cell = floor(p / 9.0);
	vec2 f = fract(p / 9.0);
	float h = hash(cell);
	float tuft = step(0.75, h) * smoothstep(0.35, 0.0, length(f - vec2(0.5)));
	c = mix(c, c * 1.18, tuft * 0.6);
	COLOR = vec4(c, COLOR.a);
}
