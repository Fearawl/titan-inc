# Titan Inc - Vertical Slice Design

Дата: 2026-04-27  
Статус: дизайн утвержден пользователем в диалоге

## 1. Контекст

`Titan Inc` - 2D pixel-art idle/incremental игра на Godot 4.6 для PC. Игрок управляет армией титанов, которая разрушает города разных эпох. Первый вертикальный срез фокусируется на fantasy-средневековом городе.

Утвержден подход: гибридная data-driven модульная архитектура.

Причины выбора:

- Контент и баланс удобно расширять через Godot `Resource`.
- Domain logic можно держать отдельно от сцен и VFX.
- Godot-сцены остаются полезными для движения, коллизий, анимаций и presentation.
- Save/load и future prestige не нужно будет встраивать поверх хаоса.

## 2. Scope первого среза

Первый город длится примерно 2-3 часа и состоит из трех зон:

1. Пригород.
2. Башни.
3. Стена.

Главный фокус:

- непрерывный спавн титанов;
- непрерывная оборона города;
- продвижение слева направо;
- разрушение строений;
- ремонт повреждений;
- ресурсы;
- покупка лимитов армии;
- первые upgrades;
- открытие prestige после героя.

Не входит:

- offline rewards;
- зум камеры;
- полноценный UI-дизайн;
- финальный вид meta-tree;
- все будущие эпохи;
- C#;
- headless/autotests.

## 3. Архитектура

Плановая структура:

```text
res://
  autoload/
    signal_bus.gd
    save_service.gd
    game_state.gd
  core/
  content/
  systems/
  world/
  actors/
  structures/
  ui/
  vfx/
  docs/
```

`content/` хранит данные и баланс.

`core/` хранит правила, расчеты, экономику, формулы, модификаторы и save state.

`systems/` управляет процессами: spawning, combat, movement, targeting, repair, progression, prestige, camera.

`actors/` и `structures/` содержат runtime-сцены и presentation.

`world/` описывает город, зоны, defense positions, lanes и objective-порядок.

Autoload:

- `SignalBus` - только глобальные события.
- `SaveService` - save/load.
- `GameState` - текущее состояние run/meta.

## 4. Resource-модель

Основные ресурсы:

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

В сейвах хранятся ids и числовые состояния, а не копии ресурсов.

## 5. Бой

Титаны:

- спавнятся слева;
- бегут вправо до стены;
- имеют лимит до 100 каждого типа;
- возрождаются по cooldown;
- атакуют AoE вокруг себя;
- ломают блокирующие здания и препятствия;
- имеют HP bar.

Защитники:

- спавнятся справа;
- получают defense position;
- удерживают позицию;
- не бегут до левого края карты;
- могут нарушать формацию при столкновении;
- часть юнитов может подниматься на башни;
- при разрушении башни падают и получают damage.

Строения:

- имеют HP;
- могут блокировать движение;
- могут быть repairable;
- могут иметь garrison slots;
- при разрушении создают debris и collapse damage.

Ремонт:

- запускается, когда оборона удерживает позиции;
- repair workers бегут из тыла к damaged repairable structures;
- ремонт постепенный и может быть прерван;
- полностью разрушенный ключевой objective по умолчанию не восстанавливается.

## 6. Экономика и progression

Ресурсы:

- `meat` - убийство живых юнитов.
- `stone` - разрушение зданий, башен, стен и препятствий.
- `metal` - убийство бронированных/вооруженных защитников и часть разрушений.
- `hero_heart` - убийство героев.

Покупка титанов означает покупку лимита армии типа.

Стартовые цены:

- Мелкий: 1 есть сразу, второй стоит 10 meat.
- Бегун: 100 meat.
- Базовый: 250 meat + 10 stone.
- Бронированный: 1000 meat + 10 metal.
- Колоссальный: 10000 meat + 1000 stone + 1000 metal.

Формула цены по умолчанию: `new_price = previous_price * 2`.

## 7. Cursor boost

Курсор постоянно усиливает союзных титанов в радиусе.

Базово усиливается damage. Через meta позже добавляются:

- attack speed;
- movement speed;
- destruction radius;
- cursor radius.

Ограничения энергии нет. Радиус отображается визуально.

## 8. Prestige

Prestige открывается после первого убийства героя.

Сбрасывается:

- run-ресурсы;
- лимиты армии;
- run-upgrades;
- прогресс города и зон.

Сохраняется:

- hero hearts;
- meta-upgrades;
- глобальные unlock-флаги.

Первый meta-screen - таблица без связей, но на `MetaUpgradeResource`.

## 9. Save/load

С первых implementation steps нужны:

- `save_version`;
- currencies;
- army limits;
- upgrade levels;
- current city/zone;
- HP поврежденных важных структур;
- defeated heroes;
- prestige availability;
- meta-upgrades;
- settings: fullscreen/windowed.

Автосейв:

- после покупки;
- после hero heart;
- после прохождения зоны;
- после prestige;
- при выходе;
- периодически.

## 10. Документация

Обязательные документы:

- `docs/gdd.md`.
- `docs/development_principles.md`.
- `docs/architecture_context.md`.
- `docs/hotfixes.md`.
- `docs/vertical_slice_spec.md`.

Документация должна обновляться вместе с архитектурными, gameplay и balancing решениями.

## 11. Следующий шаг

После ревью этой спецификации нужно создать implementation plan перед кодом.

Первый implementation package:

1. Godot project skeleton.
2. Autoload-сервисы.
3. Базовые Resource-классы.
4. Минимальный стартовый content pack.
5. Save/load простого `GameState`.
6. Titan/defender spawning с лимитами.
7. HP/damage/destruction.
8. Горизонтальное движение и defense positions.
9. Начисление ресурсов и покупка лимитов.
10. Обновление документации по факту.
