// The AO blur at a quarter of the world's resolution: a rotated 3x3
// gaussian that does not cross depth edges (corners stay crisp). Running
// at quarter resolution, its cost is a rounding error next to the AO pass
// itself.
fn post(input: PostInput) -> vec4<f32> {
    let depth = depth_at(input.uv);
    let base = textureSampleLevel(ao, linear_sampler, input.uv, 0.0).r;
    // Skip flat sky and fully lit pixels: nothing to smooth.
    if depth <= 0.0 || base > 0.999 {
        return vec4<f32>(vec3<f32>(base), 1.0);
    }
    let px = 2.0 / frame.resolution;
    var sum = base * 0.25;
    var wsum = 0.25;
    for (var i = 0; i < 12; i++) {
        let angle = f32(i) * 0.5235988 + 0.2617994;
        let uv = input.uv + vec2<f32>(cos(angle), sin(angle)) * px;
        let sdepth = depth_at(uv);
        // Only blur over pixels at about the same depth: the neighbouring
        // surface's AO, not a silhouette behind it.
        let w = select(0.0, 0.09375, abs(sdepth - depth) < 0.02);
        sum += textureSampleLevel(ao, linear_sampler, uv, 0.0).r * w;
        wsum += w;
    }
    if wsum < 0.3 {
        return vec4<f32>(vec3<f32>(base), 1.0);
    }
    return vec4<f32>(vec3<f32>(sum / wsum), 1.0);
}
