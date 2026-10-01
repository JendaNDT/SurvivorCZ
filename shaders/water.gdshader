// Kreslené moře kolem mapy: gradient, vlnky a odlesky.
shader_type canvas_item;

uniform float time_s = 0.0;
uniform vec4 deep : source_color = vec4(0.1, 0.42, 0.72, 1.0);
uniform vec4 shallow : source_color = vec4(0.22, 0.66, 0.9, 1.0);

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
	vec2 uv = SCREEN_UV;
	vec3 col = mix(shallow.rgb, deep.rgb, smoothstep(0.0, 1.0, length(uv - vec2(0.5, 0.45)) * 1.3));
	float n = noise(p * 0.012 + vec2(time_s * 0.15, time_s * 0.08));
	float n2 = noise(p * 0.03 - vec2(time_s * 0.2, 0.0));
	col *= 0.94 + 0.1 * n;
	// vlnky jako krátké světlé čárky
	vec2 cell = floor(p / vec2(90.0, 46.0));
	vec2 f = fract(p / vec2(90.0, 46.0));
	float h = hash(cell);
	float phase = fract(time_s * 0.25 + h);
	float wave = smoothstep(0.08, 0.0, abs(f.y - 0.5 - 0.08 * sin(f.x * 6.28))) * smoothstep(0.15, 0.35, f.x) * smoothstep(0.85, 0.65, f.x);
	col += vec3(0.35) * wave * step(0.55, h) * sin(phase * 3.1416);
	col += vec3(0.06) * smoothstep(0.7, 0.9, n2);
	COLOR = vec4(col, 1.0);
}
