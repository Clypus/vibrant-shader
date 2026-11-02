fn luminance(c: vec3<f32>) -> f32 {
    return dot(c, vec3<f32>(0.2126, 0.7152, 0.0722));
}

// 1 while the sun is up in the Overworld, fading out around the horizon.
fn daylight() -> f32 {
    return select(0.0, smoothstep(-0.1, 0.1, frame.sun_direction.y), frame.dimension == 0);
}

// 1 when the sun is on the horizon, 0 from a quarter of the way up.
fn sun_low() -> f32 {
    return 1.0 - smoothstep(0.0, 0.35, abs(frame.sun_direction.y));
}

// Sky light 0..1 turned into a soft ambient level, so caves stay dark.
fn ambient(light: vec2<f32>) -> f32 {
    return light.y * (0.25 + 0.75 * daylight()) + light.x * 0.15;
}

// A wind signal shared by the foliage wave: slow gusts, a light shimmer.
fn wind(t: f32, seed: f32) -> f32 {
    let gust = sin(t * 0.7 + seed) * 0.6 + sin(t * 1.9 + seed * 2.3) * 0.4;
    let shimmer = sin(t * 5.1 + seed * 4.7) * 0.15;
    return gust * 0.7 + shimmer;
}

// Vibrance: boost colours that are far from grey, leave near-neutrals alone.
fn vibrance_boost(c: vec3<f32>, amount: f32) -> vec3<f32> {
    let l = luminance(c);
    let sat = length(c - vec3<f32>(l)) / 1.7320508;
    let boost = 1.0 + amount * (1.0 - sat) * 2.0;
    return clamp(mix(vec3<f32>(l), c, boost), vec3<f32>(0.0), vec3<f32>(4.0));
}

// A soft S-curve around mid-grey.
fn filmic(c: vec3<f32>, amount: f32) -> vec3<f32> {
    let curved = c * c * (3.0 - 2.0 * c);
    return mix(c, curved, amount);
}
