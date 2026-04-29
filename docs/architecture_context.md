# Titan Inc - Architecture Context

## Current Implementation Snapshot

The first foundation package contains a Godot 4.6 project skeleton, autoload services, custom Resource classes, generated first-pass content resources, a debug city scene, basic spawning, HP/damage/destruction, resource drops, debug army-limit and run stat-upgrade purchases, JSON save/load, and cursor boost foundation.

The current visual layer uses simple rectangle actors and structures. These are temporary presentation assets; gameplay values still come from Resource data.

The next approved package is Battlefield Behavior. It adds a central battle lane, randomized titan spawn within that lane, data-driven titan and defender behavior profiles, road/defense-slot based defender movement, archer projectiles, and colossal boulder siege behavior. Detailed design: `docs/superpowers/specs/2026-04-28-battlefield-behavior-design.md`.

## Battlefield Behavior Status - 2026-04-28

Implemented:

- `RoadLane` is the central battle lane used by titan spawning and defender fallback movement.
- Titan behavior is data-driven through `UnitBehaviorProfileResource` and runtime controllers, including fighter push, runner/armored variants, and colossal siege boulder behavior.
- Defender behavior is routed through `DefenderBehaviorController`; melee defenders hold their assigned slot and ranged archers fire projectile arrows instead of applying direct resolver damage.
- Defense slots are generated as `DefenseSlotResource` content and claimed through `DefenseSlotCoordinator`. Tower garrison slots are generated with `slot_type = TOWER_GARRISON`, `range_multiplier = 2.0`, and an `anchor_structure_id`.
- `DefenderBehaviorController.effective_attack_range()` multiplies the unit attack radius/range by the assigned slot `range_multiplier`, so tower garrison assignments receive the intended 2x range bonus from slot data.
- `DefenseSlotCoordinator` now tracks occupied defenders by slot and anchor structure. When a spawned structure emits `destroyed`, the city scene forwards it to the coordinator so defenders in slots anchored to that structure take one fall-damage hit, clear their tower assignment, and resume ground fallback behavior.

Current MVP limits:

- Fall damage uses `DefenseSlotCoordinator.tower_fall_damage` until structure collapse damage profiles are wired into unit damage.
- Fallen tower defenders re-home to the road lane at their current x-position; full tower climb/fall animation and debris presentation remain future polish.

## Cursor Boost Foundation Status - 2026-04-28

Implemented:

- `UnitRuntimeModifiers` stores transient per-unit combat modifiers without mutating duplicated `stats`.
- `CombatActor.effective_damage()` applies runtime modifiers to base `stats.damage`; combat, siege melee, boulder, and arrow damage now read effective damage.
- `CursorBoostProfileResource` is generated under `content/player` and loaded through `ContentCatalog`.
- `CursorBoostController` resets titan cursor damage modifiers and reapplies the active cursor multiplier each frame before `CombatResolver` in `city_scene.tscn`.
- Temporary radius presentation draws a minimal world-space circle around the cursor.

Current MVP limits:

- Cursor boost only affects titan damage.
- Meta upgrades for attack speed, movement speed, destruction radius, and cursor radius remain future work.

## Feedback VFX Foundation Status - 2026-04-28

Implemented:

- `Damageable` now emits local `damage_taken(amount, source_id, is_critical)` signals with actual applied damage while preserving existing HP/death behavior.
- Combat roll critical metadata is forwarded through direct combat, siege melee, destructible structures, and arrow projectiles for presentation.
- `FeedbackCoordinator` is scene-owned under the city scene and scans `BattleRegistry` arrays to connect damage signals until registry registration signals exist.
- Placeholder damage popups and resource flyouts live under `vfx/` and provide readable temporary gameplay feedback.

Current MVP limits:

- Damage/resource visuals are intentionally placeholder presentation and are expected to be replaced by final pixel-art/VFX polish.
- Damage hookups scan registry arrays each frame because `BattleRegistry` does not yet emit registration lifecycle signals.

## Run Stat Upgrade Foundation Status - 2026-04-28

Implemented:

- `StatUpgradeResource` defines data-driven run upgrades for titan damage, attack rate, move speed, and attack radius using Godot Resource data.
- `ContentCatalog` loads generated stat upgrades from `content/upgrades`.
- `GameState.upgrade_levels` remains the save/reset storage for run-upgrade levels, with helper accessors for purchase code.
- `UpgradeService` handles purchase checks, payment, level increments, and live stat application without calling `SaveService`.
- Titan spawn applies matching run upgrades after `configure_titan()` by rebuilding runtime stats from `TitanTypeResource.base_stats.duplicate_stats()`, leaving base resource stats unmutated.
- Debug purchase keys `6-9` buy the four generated global titan upgrades and immediately reapply them to alive titans.

Current MVP limits:

- There is no final upgrade UI yet; debug HUD keys are temporary verification controls.
- Upgrade balance is first-pass generated content and still needs a vertical-slice pacing pass.

## UI Placeholder Art Pack Status - 2026-04-29

Implemented:

- Approved the first UI art direction as severe stone plus dark metal for early HUD readability.
- Added generated source sheets under `assets/ui/generated/sheets` for panels/buttons, resources, upgrades, and titan portraits.
- Added cropped placeholder PNG assets under `assets/ui/generated/panels`, `buttons`, `icons`, and `portraits`.
- Added transparent-background variants under `assets/ui/generated/transparent` for UI assembly and future slicing.
- Added `assets/ui/generated/README.md` to mark the pack as generated placeholder art and describe replacement boundaries.

Current MVP limits:

- These assets are not final production art.
- Panel crops still need Godot `NinePatchRect` slice-margin tuning during HUD implementation.

## HUD Foundation Status - 2026-04-29

Implemented:

- Added scene-based HUD components under `ui/hud`, `ui/shop`, and `ui/upgrades`.
- `MainHud` composes a top resource bar, left titan shop panel, and right stat-upgrade panel.
- HUD components read `GameState` and `ContentCatalog`, then delegate purchases to `GameState`, `UpgradeService`, and `SaveService` through `HudPurchaseHelpers`.
- Replaced the visual `DebugHud` instance in `world/city/city_scene.tscn` with `MainHud`.
- Moved temporary keyboard controls into non-visual `DebugHotkeys`, preserving Enter, 1-9, F5, and F9 prototype controls.

Current MVP limits:

- HUD layout is a first assembly pass and still needs visual tuning in the running editor/game viewport.
- UI still uses generated placeholder art, not final artist-made assets.
- Shop and upgrade rows are created by component scripts inside dedicated UI scenes; row subscenes can be extracted later if the rows gain more behavior.

## HUD Art Review Pass Status - 2026-04-29

Implemented:

- Added `assets/ui/generated/v2` as the first refinement pass after visual review.
- V2 frames use plain, 9-slice-safe panel and row textures without center decorations.
- Decorative iron crest art is separated into `v2/decor` and placed as independent UI nodes, not stretched inside frame textures.
- V2 resource icons, upgrade icons, and titan portraits are reduced to their intended UI display sizes to keep pixel scale closer across HUD elements.
- HUD scenes now use the V2 frame, icon, portrait, and separated-decor assets.

Current MVP limits:

- V2 assets are cleaner for UI assembly, but still generated placeholders.
- Final pixel consistency should be reviewed in the actual Godot viewport because global window scaling and texture filtering affect perceived pixel size.

Дата фиксации: 2026-04-27  
Цель: быстрый вход нового исполнителя в проект

## 1. Текущее состояние

Репозиторий содержит первый foundation package: Godot project skeleton, autoload-сервисы, Resource-модель, стартовый content pack, debug city scene, базовый спавн, бой, разрушение, ремонт, ресурсы, debug-покупки лимитов и save/load.

Утверждено:

- Godot 4.6.
- Только GDScript.
- Data-driven архитектура через Godot `Resource`.
- Модульное разделение систем.
- Достаточно строгая граница между domain logic и scene/presentation layer.
- Сейвы закладываются с первых строк.
- Central `SignalBus` разрешен, но только для глобальных событий.
- Локальные сцены используют локальные signals/coordinator nodes.

## 2. Главный дизайн первого среза

Первый вертикальный срез - средневековый fantasy-город из трех участков:

1. Пригород.
2. Башни.
3. Стена.

Ожидаемая длительность первого города: 2-3 часа.

Основная механика: армия титанов непрерывно спавнится слева, физически идет вправо, ломает здания и оборону. Защитники спавнятся справа, занимают оборонительные позиции, удерживают их и дают ремонтникам время чинить повреждения.

Игрок не может окончательно проиграть, но может быть отброшен назад по прогрессу давления.

## 3. Ключевые системы

Autoload:

- `SignalBus` - глобальные события.
- `SaveService` - save/load.
- `GameState` - текущее состояние run/meta.

Core/domain:

- stats;
- modifiers;
- costs;
- progression formulas;
- economy wallet;
- damage calculations;
- save state structures.

Gameplay systems:

- titan spawning;
- defender spawning;
- movement/steering;
- targeting;
- combat;
- repair;
- zone progression;
- prestige.

Presentation:

- actor scenes;
- structure scenes;
- HP bars;
- damage numbers;
- resource flyouts;
- debris VFX;
- camera.

## 4. Утвержденная Resource-модель

Плановые Resource-классы:

- `TitanTypeResource`.
- `DefenderTypeResource`.
- `StructureTypeResource`.
- `ZoneResource`.
- `CityResource`.
- `ArmyLimitUpgradeResource`.
- `StatUpgradeResource`.
- `MetaUpgradeResource`.
- `DropTableResource`.
- `CostResource`.
- `ProgressionFormulaResource`.
- `DamageProfileResource`.
- `SpawnRuleResource`.
- `DefensePositionResource`.

В сейвах хранятся ids и числовое состояние, а не копии ресурсов.

## 5. Бой и движение

Титаны:

- идут вправо;
- атакуют AoE вокруг себя;
- ломают блокирующие препятствия;
- не должны останавливаться ради каждого защитника, если путь вперед открыт;
- имеют HP и respawn.

Защитники:

- спавнятся справа;
- получают назначенные defense positions;
- удерживают позиции;
- могут ломать формацию при столкновении;
- некоторые могут залезать на башни;
- не бегут до левого края карты.

Ремонтники:

- появляются из тыла, когда оборона удерживает позиции;
- чинят damaged repairable structures;
- могут быть прерваны или убиты.

## 6. Экономика

Валюты:

- `meat`;
- `stone`;
- `metal`;
- `hero_heart`.

Покупка титана означает расширение лимита армии конкретного типа. Базовая формула цены: `new_price = previous_price * 2`.

В первом срезе все пять типов титанов доступны для покупки лимита:

- small;
- runner;
- basic;
- armored;
- colossal.

## 7. Prestige

Prestige открывается после первого убийства героя и не запускается автоматически.

Сбрасываются run-ресурсы, лимиты армии, run-upgrades и прогресс города.

Сохраняются hero hearts, meta-upgrades и глобальные unlock-флаги.

Первый meta-экран реализуется как таблица без связей, но данные должны быть готовы к будущему дереву.

## 8. Следующий практический шаг

Следующий пакет разработки - Battlefield Behavior:

1. Ввести battle lane как центральную боевую полосу.
2. Рандомизировать спавн титанов внутри battle lane.
3. Добавить data-driven behavior profiles для типов титанов и защитников.
4. Разделить поведение мелкого/базового, бегуна/бронированного и колоссального титанов.
5. Добавить road lane, defense slots, tower garrison slots и ambush slots для защитников.
6. Реализовать навесные стрелы лучников и бонус дальности на башнях.
7. Реализовать камень колоссального титана как отдельный projectile.
8. Обновить документацию и проверку запуска Godot.

Перед началом кода нужен отдельный implementation plan на основе `docs/superpowers/specs/2026-04-28-battlefield-behavior-design.md`.
