// Screen-space ambient occlusion at half resolution: how enclosed a point
// is, from the depth of the pixels around it. World-space radius, fixed
// eight-tap ring with per-pixel rotation, generous bilateral blur.
override ssao_strength: f32 = 0.75;
override ssao_radius: f32 = 2.0;

// A per-pixel pseudo-random 0..1 (the classic fract-sin hash).
fn hash12(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(12.9898, 78.233))) * 43758.5453);
}

fn post(input: PostInput) -> vec4<f32> {
    if ssao_strength <= 0.0 {
        return vec4<f32>(vec3<f32>(1.0), 1.0);
    }
    let depth = depth_at(input.uv);
    if depth <= 0.0 {
        return vec4<f32>(vec3<f32>(1.0), 1.0);
    }

    let p = view_position(input.uv, depth);

    // The surface's normal from the depth buffer, one half-resolution
    // texel apart.
    let px = 2.0 / frame.resolution;
    let d_x = depth_at(input.uv + vec2<f32>(px.x, 0.0));
    let d_y = depth_at(input.uv + vec2<f32>(0.0, px.y));
    let p_x = view_position(input.uv + vec2<f32>(px.x, 0.0), d_x);
    let p_y = view_position(input.uv + vec2<f32>(0.0, px.y), d_y);
    let face_normal = cross(p_x - p, p_y - p);
    let nl = length(face_normal);
    if nl < 1e-6 {
        return vec4<f32>(vec3<f32>(1.0), 1.0);
    }
    let normal = face_normal / nl;

    // Eight taps in screen space, spread over a ring whose SIZE IN THE
    // WORLD is about the radius: one half-res texel's ground at this
    // depth, scaled. The per-pixel rotation fills the ring between taps.
    let rot = hash12(input.pixel) * 6.2831853;
    var occ = 0.0;
    var count = 0.0;
    let texel_world = ssao_radius * 0.35 / max(depth, 0.1);
    for (var i = 0; i < 8; i++) {
        let angle = f32(i) * 0.7853982 + rot;
        let rr = mix(0.6, 1.0, fract(f32(i) * 0.317 + rot * 0.13));
        let offset = vec2<f32>(cos(angle), sin(angle)) * texel_world * rr;
        let suv = input.uv + offset;
        if suv.x < 0.0 || suv.x > 1.0 || suv.y < 0.0 || suv.y > 1.0 {
            continue;
        }
        let sdepth = depth_at(suv);
        if sdepth <= 0.0 {
            continue;
        }
        let sp = view_position(suv, sdepth);
        let diff = sp - p;
        let dist = length(diff);
        // Only neighbours on about the same surface, near enough to matter.
        if dist < 0.02 || dist > ssao_radius || abs(diff.y) > 0.6 {
            continue;
        }
        let dir = diff / dist;
        occ += max(dot(normal, dir), 0.0) * (1.0 - dist / ssao_radius);
        count += 1.0;
    }

    if count < 2.0 {
        return vec4<f32>(vec3<f32>(1.0), 1.0);
    }

    // Occlusion 0..1, softened and clamped so it can never band.
    let raw = clamp(1.0 - occ / count * 1.6, 0.0, 1.0);
    let ao = mix(1.0, raw, ssao_strength * exp(-length(p) * 0.008));
    return vec4<f32>(vec3<f32>(ao), 1.0);
}
