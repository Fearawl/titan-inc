# HUD Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first scene-based HUD using generated transparent placeholder PNG assets.

**Architecture:** Keep HUD as separate UI scenes and scripts under `ui/hud`, `ui/shop`, and `ui/upgrades`. Runtime UI reads `GameState` and `ContentCatalog`, then emits purchase commands through existing services instead of owning gameplay rules.

**Tech Stack:** Godot 4.6, GDScript, PNG placeholder assets, Godot `.tscn` UI scenes.

---

### Task 1: Transparent UI Asset Variants

**Files:**
- Create generated PNG variants under `assets/ui/generated/transparent/`
- Modify: `assets/ui/generated/README.md`

- [ ] Create transparent copies of panel, button, icon, and portrait PNGs by removing edge-connected neutral grey background.
- [ ] Keep original generated sheets and crops intact for future recropping.
- [ ] Inspect representative transparent outputs visually.
- [ ] Run Godot editor headless import.

### Task 2: HUD Data Helpers

**Files:**
- Create: `ui/hud/hud_purchase_helpers.gd`

- [ ] Add shared helper functions for formatting costs, querying titan purchase cost, buying titan limits, and buying stat upgrades.
- [ ] Keep gameplay decisions delegated to `GameState`, `ContentCatalog`, and `UpgradeService`.

### Task 3: Scene-Based HUD Components

**Files:**
- Create: `ui/hud/resource_bar.gd`
- Create: `ui/hud/resource_bar.tscn`
- Create: `ui/shop/titan_shop_panel.gd`
- Create: `ui/shop/titan_shop_panel.tscn`
- Create: `ui/upgrades/stat_upgrade_panel.gd`
- Create: `ui/upgrades/stat_upgrade_panel.tscn`
- Create: `ui/hud/main_hud.gd`
- Create: `ui/hud/main_hud.tscn`

- [ ] Resource bar shows meat, stone, metal, and hero hearts with generated icons.
- [ ] Titan shop panel shows five titan entries with portraits, current limit, and next cost.
- [ ] Upgrade panel shows four run stat upgrades with icons, level, and next cost.
- [ ] Main HUD composes the component scenes and keeps the battlefield visible.

### Task 4: City Scene Integration

**Files:**
- Modify: `world/city/city_scene.tscn`

- [ ] Replace the visual debug HUD instance with `main_hud.tscn`.
- [ ] Preserve debug keyboard input for resources, purchases, and save/load during prototyping.

### Task 5: Documentation and Verification

**Files:**
- Modify: `docs/architecture_context.md`

- [ ] Document that HUD Foundation uses generated placeholder art and separate UI scenes.
- [ ] Run `Godot --headless --path . --editor --quit`.
- [ ] Run `Godot --headless --path . --quit-after 120`.
- [ ] Run `git diff --check`.
- [ ] Commit the package.

