# Vibrant

A shader pack for [Horizon](https://github.com/horizon-rust/horizon), the Rust rewrite of Minecraft: Java Edition. Vibrance, real sun shadows, screen-space ambient occlusion, god rays, rippling water with reflections, waving foliage and coloured block light — designed to hold 60+ FPS on weak, integrated GPUs.

**Measured, not promised** — on an AMD Radeon Vega 8 (integrated, laptop):

| | FPS | GPU frame |
|---|---|---|
| Vanilla (no shaders) | 148 | 6.0 ms |
| **Vibrant, advanced shading off** | **70** | 11.5 ms |
| **Vibrant, advanced shading on** (real sun shadows) | **70** | 11.7 ms |

Every stage that can run at quarter or half resolution does; the pack's only full-resolution pass is the final grade. On a 60 Hz display both modes stay comfortably above vsync.

## Install

Requires Horizon with shader pack support (any 26.3 nightly).

1. Download `vibrant-<version>.hshader` from [releases](../../releases)
2. `horizon-launcher packs add vibrant-<version>.hshader`
3. `horizon-launcher packs on vibrant --kind shader`

## Features

- **Advanced shading** (toggle in-game, off by default) — a real 1024² sun shadow map with normal-offset sampling and PCF; trees, blocks and terrain cast shadows that stretch at sunset. Off = fully lit vanilla surfaces, zero shadow reads.
- **Ambient occlusion** — half-resolution SSAO with per-pixel rotated sampling and a depth-aware bilateral blur: soft contact shadows in corners, under trees and inside, without bands or blobs on open ground.
- **Bloom** — quarter-resolution, a fused bright-pass and blur in one pass.
- **God rays** — screen-space light shafts toward the sun, quarter resolution, auto-disabled when facing away.
- **Water** — world-space wave trains ripple the reflection; Fresnel decides between seeing through and mirroring. Vanilla water colour is never darkened.
- **Waving foliage** — grass and leaves shimmer with the wind through lighting, not texture slides (no torn sprite edges).
- **Coloured block light** — torches warm, soul fire cold, lava red: five light families tint their surroundings at night.
- **Filmic grade** — ACES tonemapping, vibrance, saturation, a light S-curve, dusk warmth, rain desaturation, optional vignette.

## Options

All in `Options > Horizon Settings > Shader Packs > Shader Options`, applied live:

| Option | Meaning |
|---|---|
| Advanced shading | Real sun shadows + directional light colouring |
| Ambient occlusion / AO radius | Corner darkening strength and reach |
| Bloom | Halo around bright pixels |
| Sun shafts | God rays through trees |
| Waving leaves | Foliage wind |
| Water reflections | Water clarity, reflection strength, wave size |
| World reflections | Solid surfaces pick up a glossy sheen at glancing angles |
| Vibrance / Saturation / Contrast / Vignette | The grade |

## Building from source

```
git clone https://github.com/Clypus/vibrant-shader
cd vibrant-shader
horizon-shader pack .   # writes vibrant-<version>.hshader
```

`horizon-shader` ships with Horizon's source tree (`crates/horizon-shader-api`).

## License

MIT
