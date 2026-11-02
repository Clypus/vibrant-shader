override shadow_darkness: f32 = 0.55;
override leaf_wave: f32 = 0.5;
override water_fade: f32 = 0.5;
override shadow_softness: f32 = 0.5;
override world_reflections: bool = false;
override advanced_shading: bool = false;

fn foliage_offset(position: vec3<f32>) -> vec3<f32> {
    let phase = dot(floor(position + frame.camera_position), vec3<f32>(0.37, 0.61, 0.53));
    let sway = wind(frame.time, phase * 0.35);
    let sway2 = wind(frame.time * 1.3, phase * 0.21 + 1.7);
    let top = fract(position.y);
    let amp = mix(0.02, 0.07, smoothstep(0.3, 1.0, top));
    return vec3<f32>(sway, sway2 * 0.3, sway * 0.6) * amp * leaf_wave;
}

fn sunlit(position: vec3<f32>, normal: vec3<f32>) -> f32 {
    // Advanced shading off: no shadow reads at all, fully lit.
    if !advanced_shading {
        return 1.0;
    }
    let ndl = dot(normal, frame.light_direction);
    if ndl <= 0.0 {
        return 0.0;
    }
    if frame.has_shadow == 0u {
        return 1.0;
    }
    // Out of the map's square: lit, without the read.
    if length(position.xz) > frame.shadow_distance * 1.4 {
        return 1.0;
    }
    // Normal offset against self-shadowing acne, then one comparison
    // widened by the sampler's own 2x2 PCF.
    let world_offset = normal * frame.shadow_center_texel * 1.4
        + normalize(frame.light_direction) * frame.shadow_center_texel;
    let p = shadow_position(position + world_offset);
    let bias = 0.0018 + shadow_softness * 0.0008;
    return textureSampleCompareLevel(shadow_map, shadow_sampler, p.xy, p.z - bias);
}

fn material(input: MaterialInput) -> Surface {
    var surface: Surface;
    var albedo = input.albedo.rgb * input.tint.rgb;
    var alpha = input.albedo.a;
    // Foliage wave: shade the sprite along the wind instead of sliding
    // its texture (a slid sample crosses sprite edges and tears).
    if (input.tags & 1u) != 0u && leaf_wave > 0.0 {
        let offset = foliage_offset(input.position);
        let wave_light = 1.0 + (offset.x + offset.y) * 2.2;
        albedo *= clamp(wave_light, 0.72, 1.28);
    }
    let n = input.normal;
    let day = daylight();
    let sun = sunlit(input.position, n);
    let ndl = max(dot(n, frame.light_direction), 0.0);
    let shadow_factor = select(1.0, mix(1.0 - shadow_darkness, 1.0, sun), advanced_shading);
    var color = albedo * input.lightmap * shadow_factor;
    let direct = select(0.0, ndl * sun * day * (1.0 - frame.rain * 0.6), advanced_shading);
    color *= mix(vec3<f32>(0.88, 0.95, 1.10), vec3<f32>(1.05, 1.00, 0.93), direct);
    if input.light.x > 0.05 {
        let light_tint = block_light_color(input.position);
        let tinted_block = mix(vec3<f32>(1.0), light_tint.rgb, min(light_tint.a, 1.0) * 0.8);
        color *= mix(vec3<f32>(1.0), tinted_block, input.light.x * (1.0 - day * 0.35));
    }
    // Water: Fresnel reflection over vanilla's own water colour.
    if input.fluid == 1u {
        let view_dir = normalize(-input.position);
        let fresnel = pow(1.0 - clamp(dot(view_dir, n), 0.0, 1.0), 3.0);
        var reflected = vec3<f32>(0.0);
        if frame.has_reflection == 1u && water_fade > 0.0 {
            let wp = input.position + frame.camera_position;
            let wave1 = sin(dot(wp.xz, vec2<f32>(0.55, 0.30)) + frame.time * 1.5);
            let wave2 = sin(dot(wp.xz, vec2<f32>(-0.28, 0.62)) + frame.time * 1.1);
            let wave3 = sin(dot(wp.xz, vec2<f32>(0.90, -0.45)) + frame.time * 2.2);
            let swell = (wave1 * 0.5 + wave2 * 0.35 + wave3 * 0.15);
            let slide = vec2<f32>(wave1 * 0.7 + wave2 * 0.3, wave2 * 0.6 + wave3 * 0.4);
            let ripple = slide * 0.018 * water_fade * mix(0.4, 1.0, fresnel);
            reflected = textureSampleLevel(reflection, reflection_sampler, input.screen + ripple, 0.0).rgb;
            color += vec3<f32>(-0.02, -0.01, 0.0) * swell * water_fade;
        }
        let base = albedo * input.lightmap;
        let refl_amount = clamp(fresnel * mix(0.3, 0.75, water_fade), 0.0, 0.55);
        color = mix(color, max(reflected, base * 0.9), refl_amount);
        let spec = pow(max(dot(reflect(-frame.light_direction, n), view_dir), 0.0), 90.0) * sun * day;
        color += vec3<f32>(1.0, 0.95, 0.85) * spec * 0.6;
    }

    // Emissive blocks keep their glow.
    color += albedo * input.emission * 1.4;

    // World reflections: solid surfaces pick up a whisper of the water
    // mirror at glancing angles. Off by default: exactly vanilla when off.
    if input.fluid == 0u && world_reflections {
        let view_dir2 = normalize(-input.position);
        let facing = 1.0 - clamp(dot(view_dir2, n), 0.0, 1.0);
        if facing > 0.55 && frame.has_reflection == 1u {
            let sheen = pow(facing, 3.0) * 0.22;
            let mirrored = textureSampleLevel(reflection, reflection_sampler, input.screen, 0.0).rgb;
            color = mix(color, max(mirrored, color * 0.85), sheen);
        }
    }

    surface.color = vec4<f32>(color, alpha);
    return surface;
}
