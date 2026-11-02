// Bloom in one pass, at a quarter of the world's resolution: the
// bright-pass and the blur fused — a centre tap and a rotated ring of 4
// taps, each bilinear tap covering two texels. The grade reads the result
// bilinearly upscaled, which smooths it further for free.
override bloom: f32 = 0.6;

fn bright(uv: vec2<f32>) -> vec3<f32> {
    let c = textureSampleLevel(previous, linear_sampler, uv, 0.0).rgb;
    let sky = select(1.0, 0.25, depth_at(uv) == 0.0);
    return c * smoothstep(0.75, 1.0, luminance(c)) * sky;
}

fn post(input: PostInput) -> vec4<f32> {
    if bloom <= 0.0 {
        return vec4<f32>(vec3<f32>(0.0), 1.0);
    }
    let step = frame.resolution.y / 720.0 / frame.resolution;
    var sum = bright(input.uv) * 0.34;
    for (var i = 0; i < 4; i++) {
        let angle = f32(i) * 1.5707963 + 0.7853982;
        let radius = mix(4.0, 9.0, clamp(bloom * 0.5 + 0.5, 0.0, 1.0));
        let offset = vec2<f32>(cos(angle), sin(angle)) * radius * step;
        sum += bright(input.uv + offset) * 0.165;
    }
    return vec4<f32>(sum * bloom, 1.0);
}
