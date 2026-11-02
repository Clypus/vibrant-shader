// The vibrant grade, the pack's only full-resolution pass: ACES filmic
// tonemapping, vibrance, the bloom halo, sun shafts, ambient occlusion,
// coloured highlights, weather washes and a vignette, all in one pass.
override vibrance: f32 = 0.55;
override saturation: f32 = 1.25;
override contrast: f32 = 0.3;
override vignette: bool = true;
override ssao_strength: f32 = 0.5;

// ACES filmic approximation (Narkowicz 2015): industry-standard highlight
// rolloff. Pure ALU: no texture, no bandwidth.
fn aces(x: vec3<f32>) -> vec3<f32> {
    let a = 2.51; let b = 0.03; let c = 2.43; let d = 0.59; let e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), vec3<f32>(0.0), vec3<f32>(1.0));
}

fn post(input: PostInput) -> vec4<f32> {
    var c = input.color.rgb;

    // Vibrance then saturation, in linear-light space.
    c = vibrance_boost(c, vibrance);
    c = mix(vec3<f32>(luminance(c)), c, saturation);

    // The bloom halo and the sun shafts.
    c += textureSampleLevel(halo, linear_sampler, input.uv, 0.0).rgb;
    if input.depth > 0.0 {
        c += textureSampleLevel(shafts, linear_sampler, input.uv, 0.0).rgb;
    }

    // Ambient occlusion: corner and interior darkening, sky untouched,
    // already smoothed by the AO blur pass; one bilinear tap is enough.
    if input.depth > 0.0 {
        let ao_v = textureSampleLevel(ao_smooth, linear_sampler, input.uv, 0.0).r;
        c *= mix(1.0, ao_v, 0.7);
    }

    // A low sun washes the whole picture warm; the day cools its highlights.
    let hi = smoothstep(0.55, 1.0, luminance(c));
    let day = daylight();
    let dusk = sun_low();
    let warm = vec3<f32>(1.04, 0.99, 0.92) * dusk;
    let cool = vec3<f32>(0.98, 0.995, 1.03);
    c *= mix(vec3<f32>(1.0), mix(warm, cool, 1.0 - dusk), hi * 0.5 * day);
    let dusk_wash = vec3<f32>(1.06, 1.0, 0.94);
    c *= mix(vec3<f32>(1.0), dusk_wash, dusk * day * 0.6);

    // Rain: desaturate and cool.
    c = mix(c, c * vec3<f32>(0.9, 0.95, 1.02), frame.wetness * 0.5);
    c = mix(c, vec3<f32>(luminance(c)), frame.rain * 0.25);

    // Underwater: pull toward teal and soften.
    c = mix(c, c * vec3<f32>(0.8, 0.95, 1.05) + vec3<f32>(0.0, 0.02, 0.04), frame.in_water * 0.7);

    // Exposure headroom, then ACES, then a light S-curve for contrast.
    c *= 1.1;
    c = aces(c);
    c = filmic(c, contrast * 0.6);

    if vignette {
        let aspect = frame.resolution.x / frame.resolution.y;
        let d = length((input.uv - 0.5) * vec2<f32>(aspect, 1.0)) / length(vec2<f32>(aspect, 1.0) * 0.5);
        c *= 1.0 - smoothstep(0.55, 1.1, d) * 0.35;
    }

    return vec4<f32>(c, input.color.a);
}
