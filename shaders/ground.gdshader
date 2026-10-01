// Procedurální textura země – tráva, dlažba, hlína, sníh, les, vinice, plech, pole, louka.
// Vše se počítá v shaderu ze souřadnic světa, žádné obrázky.
shader_type canvas_item;

uniform int pattern = 0;
uniform vec4 col_a : source_color = vec4(0.43, 0.81, 0.24, 1.0);
uniform vec4 col_b : source_color = vec4(0.31, 0.68, 0.16, 1.0);
uniform vec4 col_c : source_color = vec4(0.85, 0.8, 0.7, 1.0);
uniform float time_s = 0.0;

varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	p = mod(p, 512.0);
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 hash2(vec2 p) {
	p = mod(p, 512.0);
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// x = vzdálenost k nejbližšímu bodu, y = vzdálenost k hraně buňky, z = náhodné id buňky
vec3 voronoi(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	vec2 mg = vec2(0.0);
	vec2 mr = vec2(0.0);
	float md = 8.0;
	for (int j = -1; j <= 1; j++)
	for (int i = -1; i <= 1; i++) {
		vec2 g = vec2(float(i), float(j));
		vec2 o = hash2(n + g) * 0.8 + 0.1;
		vec2 r = g + o - f;
		float d = dot(r, r);
		if (d < md) { md = d; mr = r; mg = g; }
	}
	float ed = 8.0;
	for (int j = -1; j <= 1; j++)
	for (int i = -1; i <= 1; i++) {
		vec2 g = mg + vec2(float(i), float(j));
		vec2 o = hash2(n + g) * 0.8 + 0.1;
		vec2 r = g + o - f;
		if (dot(mr - r, mr - r) > 0.00001)
			ed = min(ed, dot(0.5 * (mr + r), normalize(r - mr)));
	}
	return vec3(sqrt(md), ed, hash(n + mg));
}

// Trsy trávy: světlé „véčko“ v náhodných místech mřížky
float tufts(vec2 p, float cell) {
	vec2 c = floor(p / cell);
	vec2 f = p / cell - c;
	vec2 o = hash2(c) * 0.6 + 0.2;
	vec2 d = (f - o) * cell;
	float k = 0.0;
	if (hash(c + 7.0) < 0.55) {
		for (int i = -1; i <= 1; i++) {
			vec2 q = d - vec2(float(i) * 3.5, 0.0);
			float blade = smoothstep(1.4, 0.4, abs(q.x + q.y * 0.25 * float(i))) * smoothstep(0.0, -1.0, q.y) * smoothstep(-9.0, -3.0, q.y);
			k = max(k, blade);
		}
	}
	return k;
}

vec3 grass(vec2 w, vec3 a, vec3 b) {
	float big = fbm(w * 0.0035);
	vec3 col = mix(b, a, smoothstep(0.3, 0.7, big));
	col *= 0.93 + 0.12 * noise(w * 0.05);
	float t = tufts(w, 46.0);
	col = mix(col, a * 1.18, t * 0.55);
	float t2 = tufts(w + vec2(17.0, 29.0), 31.0);
	col = mix(col, b * 0.82, t2 * 0.35);
	return col;
}

void fragment() {
	vec2 w = wpos;
	vec3 a = col_a.rgb;
	vec3 b = col_b.rgb;
	vec3 c = col_c.rgb;
	vec3 col = a;

	if (pattern == 0) {
		// tráva s cestičkami z oblázků
		col = grass(w, a, b);
		float path = abs(fbm(w * 0.0012 + 3.0) - 0.5);
		if (path < 0.02) {
			vec3 v = voronoi(w / 22.0);
			vec3 stone = c * (0.85 + 0.25 * v.z);
			stone = mix(stone * 0.6, stone, smoothstep(0.02, 0.12, v.y));
			col = mix(col, stone, smoothstep(0.02, 0.014, path));
		}
	} else if (pattern == 1) {
		// dlažební kostky
		vec3 v = voronoi(w / 34.0);
		vec3 stone = mix(b, a, v.z) * (0.92 + 0.12 * noise(w * 0.08));
		float edge = smoothstep(0.03, 0.14, v.y);
		col = mix(c, stone, edge);
		col += vec3(0.08) * smoothstep(0.14, 0.3, v.y) * (1.0 - v.x);
	} else if (pattern == 2) {
		// hlína s kameny a uhlím
		float n = fbm(w * 0.006);
		col = mix(b, a, smoothstep(0.25, 0.75, n));
		col *= 0.9 + 0.15 * noise(w * 0.07);
		vec3 v = voronoi(w / 60.0);
		if (v.z > 0.72) {
			float pebble = smoothstep(0.24, 0.18, v.x);
			col = mix(col, mix(c, c * 1.6, step(0.86, v.z)), pebble);
		}
		float tracks = smoothstep(0.012, 0.0, abs(fract(w.y / 300.0 + noise(w * 0.002) * 0.3) - 0.5) - 0.06);
		col *= 1.0 - tracks * 0.12;
	} else if (pattern == 3) {
		// sníh
		float n = fbm(w * 0.004);
		col = mix(b, a, smoothstep(0.2, 0.8, n));
		col = mix(col, c, smoothstep(0.62, 0.8, fbm(w * 0.01 + 5.0)) * 0.35);
		float sp = step(0.985, hash(floor(w / 6.0)));
		col += vec3(sp) * 0.25 * (0.5 + 0.5 * sin(time_s * 3.0 + hash(floor(w / 6.0)) * 20.0));
	} else if (pattern == 4) {
		// lesní půda s jehličím
		col = grass(w, a, b);
		float leaf = smoothstep(0.55, 0.75, fbm(w * 0.008 + 11.0));
		col = mix(col, c * (0.85 + 0.3 * noise(w * 0.3)), leaf * 0.85);
	} else if (pattern == 5) {
		// vinice: pruhy hlíny a trávy
		float row = abs(fract(w.x / 150.0) - 0.5) * 2.0;
		vec3 soil = mix(b, a, noise(w * 0.05)) * (0.9 + 0.15 * noise(w * 0.2));
		vec3 gr = grass(w, c, c * 0.8);
		col = mix(gr, soil, smoothstep(0.55, 0.62, row));
	} else if (pattern == 6) {
		// ocelové pláty s nýty a žhavými prasklinami
		vec2 cell = floor(w / 128.0);
		vec2 f = fract(w / 128.0);
		float shade = hash(cell) * 0.15;
		col = mix(b, a, 0.5 + shade) * (0.9 + 0.1 * noise(w * 0.05));
		float rust = smoothstep(0.55, 0.8, fbm(w * 0.01 + cell));
		col = mix(col, vec3(0.55, 0.32, 0.18), rust * 0.6);
		float seam = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
		col *= mix(0.55, 1.0, smoothstep(0.0, 0.025, seam));
		col += vec3(0.1) * smoothstep(0.03, 0.05, seam) * (1.0 - smoothstep(0.05, 0.07, seam)) * step(f.y, 0.5);
		vec2 rv = abs(f - 0.5);
		float rivet = smoothstep(0.022, 0.012, length(vec2(rv.x, rv.y) - vec2(0.42)));
		col = mix(col, b * 1.3, rivet);
		float crack = abs(fbm(w * 0.004 + 40.0) - 0.5);
		float glow = smoothstep(0.012, 0.0, crack) * (0.75 + 0.25 * sin(time_s * 2.0 + w.x * 0.01));
		col = mix(col, c, glow);
	} else if (pattern == 7) {
		// pole: zlaté pruhy obilí
		float stripe = 0.5 + 0.5 * sin((w.x + w.y * 0.35) * 0.06 + noise(w * 0.01) * 4.0);
		col = mix(b, a, stripe * 0.6 + 0.4 * fbm(w * 0.005));
		col *= 0.92 + 0.1 * noise(w * 0.25);
		float patch = smoothstep(0.62, 0.7, fbm(w * 0.003 + 9.0));
		col = mix(col, grass(w, c, c * 0.8), patch);
	} else {
		// louka s pruhy po sekačce a tůňkami
		col = grass(w, a, b);
		float stripe = step(0.5, fract(w.x / 220.0));
		col *= 0.95 + 0.07 * stripe;
		float pond = fbm(w * 0.0022 + 2.0);
		if (pond > 0.66) {
			vec3 water = c * (0.9 + 0.15 * sin(time_s * 1.5 + w.x * 0.03 + w.y * 0.02));
			float edge = smoothstep(0.66, 0.675, pond);
			col = mix(col * 0.7, water, edge);
			col += vec3(0.25) * smoothstep(0.69, 0.7, pond) * step(0.7, noise(w * 0.05 + time_s * 0.3)) * edge;
		}
	}
	COLOR = vec4(col, 1.0);
}
