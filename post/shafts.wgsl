// God rays: the sun's light scattered through the air, as a radial march in
// screen space toward the sun at half resolution. Occluders (terrain) block
// the light; the temporal pass then smooths the shafts over frames, so few
// steps look like many.
override sun_shafts: f32 = 0.55;

fn post(input: PostInput) -> vec4<f32> {
    let strength = sun_shafts * daylight() * (1.0 - frame.rain * 0.85);
    if strength <= 0.0 {
        return vec4<f32>(vec3<f32>(0.0), 1.0);
    }
    // The sun on screen; no shafts when it is behind us.
    let sun_clip = frame.projection * frame.view * vec4<f32>(frame.sun_direction * 100.0, 1.0);
    let sun_uv = (sun_clip.xy / sun_clip.w) * 0.5 + 0.5;
    let to_sun = sun_uv - input.uv;
    if sun_clip.w <= 0.0 || to_sun.x * to_sun.x + to_sun.y * to_sun.y < 0.0001 {
        return vec4<f32>(vec3<f32>(0.0), 1.0);
    }
    let dist = length(to_sun);
    let dir = to_sun / dist;

    // 5 steps of the sky's visibility along the ray to the sun; a quarter
    // resolution hides the coarseness, the grade's bilinear upscale smooths
    // the rest.
    var light = 0.0;
    let steps = 5;
    for (var i = 0; i < steps; i++) {
        let t = (f32(i) + 0.5) / f32(steps);
        let pos = input.uv + dir * dist * t * 0.85;
        let sky = select(1.0, 0.0, depth_at(pos) > 0.0);
        // Fade out toward the sun so the disc itself does not blow out.
        light += sky * (1.0 - t);
    }
    light /= f32(steps);

    // Stronger toward the sun, softer out at the edges.
    let falloff = exp(-dist * 2.2);
    let warm = mix(vec3<f32>(1.0, 0.85, 0.65), vec3<f32>(1.0, 0.95, 0.85), 0.5);
    let color = warm * light * falloff * strength * 0.8;
    return vec4<f32>(color, 1.0);
}
