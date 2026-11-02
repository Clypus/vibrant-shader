// A vivid sky: deeper blues by day, rich sunsets, a hint of teal at night.
override vibrance_sky: f32 = 0.4;

fn sky(input: SkyInput) -> vec4<f32> {
    let d = input.direction;
    let day = daylight() * (1.0 - frame.rain * 0.8);
    let dusk = sun_low() * day;

    // Deeper overhead blue while the horizon keeps vanilla's colour.
    let zenith = smoothstep(0.0, 1.0, d.y) * day;
    var c = input.color.rgb;
    c = mix(c, c * vec3<f32>(0.78, 0.90, 1.12), zenith * vibrance_sky * 0.6);

    // Sunset band: warm the air low around the sun's side of the sky.
    let toward = max(dot(d, frame.sun_direction), 0.0);
    let band = (1.0 - smoothstep(0.0, 0.45, abs(d.y))) * pow(toward, 2.0);
    c += vec3<f32>(1.0, 0.45, 0.15) * band * dusk * 0.35;

    // Night: push toward deep blue-teal.
    let night = 1.0 - day;
    let horizon_band = 1.0 - smoothstep(0.0, 0.5, abs(d.y));
    let deep = vec3<f32>(0.015, 0.035, 0.075) * (0.5 + 0.5 * horizon_band);
    c = mix(c, deep, night * 0.75);

    // Rain: grey and flat.
    c = mix(c, vec3<f32>(luminance(c)) * 0.85, frame.rain * 0.7);

    return vec4<f32>(c, input.color.a);
}
