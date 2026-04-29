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

## Notes

- Panel crops are first-pass candidates for `NinePatchRect` setup and may need manual slice-margin tuning in Godot.
- Icon and portrait crops are ready as visual placeholders for HUD cards.
- The source sheets are kept so later slicing can be adjusted without regenerating the whole art direction.

