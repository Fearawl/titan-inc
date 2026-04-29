# Titan Inc Generated UI Placeholder Art

Status: placeholder art, not final production art.

This folder contains generated raster UI assets for early HUD prototyping. The approved direction is severe stone plus dark metal: cold masonry, iron borders, rivets, dark readable centers, and restrained crimson accents.

These files are intentionally replaceable. UI scenes should reference stable asset paths, but gameplay logic must not depend on any visual details in these images.

## Source Sheets

- `sheets/ui_panels_buttons_sheet_v1.png`
- `sheets/resource_icons_sheet_v1.png`
- `sheets/upgrade_icons_sheet_v1.png`
- `sheets/titan_portraits_sheet_v1.png`

## Cropped Runtime Candidates

- `panels/`: top resource bar, left titan shop panel, right upgrade panel.
- `buttons/`: normal, hover, pressed, disabled button states.
- `icons/resources/`: meat, stone, metal, hero heart.
- `icons/upgrades/`: damage, attack speed, movement speed, destruction radius.
- `portraits/titans/`: small, runner, basic, armored, colossal titan portraits.
- `transparent/`: transparent-background variants of the same sheets and crops for HUD assembly and future slicing.
- `v2/frames/`: simplified 9-slice-safe panel and row frames without center decorations.
- `v2/decor/`: separated decorative ornaments that can be placed as independent `TextureRect` nodes.
- `v2/icons/` and `v2/portraits/`: reduced 1:1 UI-size icons and portraits for a more consistent pixel scale.

## Notes

- Panel crops are first-pass candidates for `NinePatchRect` setup and may need manual slice-margin tuning in Godot.
- Icon and portrait crops are ready as visual placeholders for HUD cards.
- The source sheets are kept so later slicing can be adjusted without regenerating the whole art direction.
- Prefer transparent variants for actual UI scenes. Keep opaque originals as visual sources and fallback references.
- Prefer `v2` assets for HUD implementation. They address the first UI review pass: consistent pixel scale, lighter frames, and separate decoration instead of stretched center ornaments.
