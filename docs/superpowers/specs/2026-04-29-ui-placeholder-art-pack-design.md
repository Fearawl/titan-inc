# Titan Inc - UI Placeholder Art Pack Design

Date: 2026-04-29
Status: approved direction; design written for user review

## 1. Context

The current prototype uses mostly rectangular debug presentation. This is enough for system testing, but it makes the game harder to read and does not communicate the intended harsh fantasy siege tone.

The next visual package should create replaceable UI placeholder art before the full HUD implementation. These assets are not final production art. They are a style bridge: close enough to the target mood to improve testing, but structured so a dedicated artist can replace them without rebuilding UI scenes.

## 2. Approved Visual Direction

The approved direction is severe stone plus dark metal.

Mood:

- medieval siege;
- heavy, practical, worn surfaces;
- cold stone, iron rivets, dark inner panels;
- restrained blood-red accents only where useful for danger, damage, or disabled states;
- no warm parchment/shop UI as the main identity;
- no direct copying of reference images.

The UI should feel like field equipment attached to a siege command interface, not like a clean mobile idle template.

## 3. Scope

This package creates a small UI placeholder art pack for the future HUD foundation:

- stretchable panel frames for top resources, titan shop, and stat upgrades;
- button states: normal, hover, pressed, disabled;
- resource icons: meat, stone, metal, hero heart;
- upgrade icons: damage, attack speed, movement speed, destruction radius;
- titan portrait placeholders: small, runner, basic, armored, colossal.

Out of scope:

- final HUD layout implementation;
- final pixel-perfect production art;
- animated UI transitions;
- final fonts and localization treatment;
- meta tree art;
- battlefield sprites and environment tiles.

## 4. Asset Requirements

Panel and button assets must be usable with Godot UI scenes:

- panel images should be prepared for `NinePatchRect` usage;
- corners and borders must remain readable after stretching;
- center areas should be dark and calm enough for white/yellow text;
- buttons must have clear state differences without relying only on text;
- icon silhouettes must stay readable at small sizes.

Recommended initial target sizes:

- panel source: 256x128 or 512x256;
- square buttons: 96x96 or 128x128;
- resource and upgrade icons: 128x128 source, used smaller in UI;
- titan portraits: 192x192 or 256x256 source.

All generated assets should be saved under project folders, for example:

```text
res://assets/ui/generated/
  panels/
  buttons/
  icons/resources/
  icons/upgrades/
  portraits/titans/
```

## 5. Generation Approach

Use generated raster images as source material, then keep the final project assets as PNG files inside the repository.

The first generation pass should produce a small number of variants, not a huge batch:

1. panel and button style sheet candidate;
2. resource icon sheet candidate;
3. titan portrait mood candidate.

After visual review, selected images can be cut into separate PNG files and wired into UI scenes in a later HUD package.

## 6. Implementation Boundaries

This art package should not change gameplay logic.

If helper scripts are needed for slicing, trimming, or chroma-key removal, they should live in tooling or temporary generation folders and must not become runtime dependencies. Project-facing outputs are normal PNG files.

Generated art is placeholder content. Code and scenes should reference it through stable paths and replaceable resources, not through hardcoded assumptions about final visuals.

## 7. Acceptance Criteria

The package is ready for the next HUD implementation step when:

- at least one coherent severe stone plus dark metal UI direction exists as project PNG assets;
- resource icons are visually distinct from each other;
- upgrade icons are visually distinct from resource icons;
- titan portraits communicate five different titan classes at placeholder level;
- assets are stored inside the workspace, not only in external generated-image folders;
- documentation records that these are replaceable generated placeholders.
