# Titan Inc - Development Principles

Дата фиксации: 2026-04-27  
Статус: обязательные правила разработки

## 1. Технологии

- Движок: Godot 4.6.
- Язык: только GDScript.
- Целевая платформа: PC.
- Игра offline-first.
- Контент и баланс строятся data-driven через кастомные Godot `Resource`.

## 2. Архитектурный подход

Утвержден гибридный data-driven модульный подход:

- Контент и баланс описываются `Resource`.
- Domain/core-слой считает правила, экономику, статы, урон, цены и сохранения.
- Scene/presentation-слой отвечает за движение узлов, анимации, VFX, collision, HP bars и отображение.
- Системы разделяются по ответственностям: spawning, combat, movement, targeting, repair, progression, prestige, camera.

Этот подход выбран вместо быстрого scene-first прототипа и вместо полностью изолированной domain simulation. Он сохраняет строгие границы, но не мешает использовать сильные стороны Godot.

## 3. Границы слоев

Core/domain:

- не зависит от конкретных сцен, текстур, анимаций и VFX;
- не должен обращаться к UI напрямую;
- работает с ids, stats, costs, modifiers, formulas, state.

Scene/presentation:

- читает данные из ресурсов;
- показывает runtime-состояние;
- отправляет события системам;
- не принимает окончательные решения об экономике, прогрессе и сейвах.

Systems:

- связывают domain-правила и runtime-сцены;
- координируют процессы внутри текущей сцены или игры;
- используют локальные signals там, где событие не нужно всей игре.

## 4. Signals и Event Bus

Допускается центральный autoload `SignalBus`, но его нельзя перегружать.

`SignalBus` используется для глобальных событий:

- resource_changed;
- resource_gained;
- structure_destroyed;
- zone_completed;
- save_loaded;
- prestige_completed;
- hero_defeated;

Локальные события остаются локальными:

- башня сообщает своим защитникам о разрушении;
- спавнер сообщает зоне о лимите;
- repair coordinator выдает цели ремонтникам;
- damageable-объект сообщает локальной сцене об изменении HP.

## 5. Save с первых строк

Сохранения являются базовой системой, а не поздней надстройкой.

Правила:

- Сохраняем только ids и числовое runtime-состояние.
- Не сохраняем копии `Resource`.
- Каждый сейв имеет `save_version`.
- `SaveService` отвечает за serialization/deserialization.
- `GameState` хранит текущее состояние run и meta-прогресса.

События автосейва:

- покупка;
- получение hero heart;
- прохождение зоны;
- prestige;
- выход из игры;
- периодический autosave.

## 6. Naming conventions

Файлы и папки:

- `snake_case`.

GDScript classes и Resources:

- `PascalCase` через `class_name`.

Resource ids:

- `snake_case`: `small_titan`, `suburb_zone`, `meat_drop`.

Autoload names:

- `PascalCase`: `SignalBus`, `SaveService`, `GameState`.

## 7. Planned project structure

```text
res://
  autoload/
  core/
    ids/
    math/
    modifiers/
    stats/
    economy/
    combat/
  content/
    titans/
    defenders/
    structures/
    zones/
    upgrades/
    drops/
    formulas/
  systems/
    spawning/
    combat/
    movement/
    targeting/
    repair/
    progression/
    prestige/
    camera/
  world/
    city/
    zones/
    defense_positions/
    lanes/
  actors/
    titan/
    defender/
    repair_worker/
  structures/
    destructible/
    wall/
    tower/
    gate/
    building/
  ui/
    hud/
    shop/
    stats/
    prestige/
    meta_table/
  vfx/
    damage_numbers/
    resource_flyouts/
    debris/
  docs/
```

## 8. Resource-first rules

Все контентные значения должны идти через `Resource`, если значение влияет на баланс, прогресс, поведение юнитов, стоимость, дроп или структуру города.

Запрещено хардкодить в сценах:

- HP;
- damage;
- attack rate;
- move speed;
- attack radius;
- spawn cooldown;
- army limit;
- costs;
- drop tables;
- repair rules;
- zone completion rules.

Допустимо временно хардкодить только presentation-заглушки, если это не влияет на game rules.

## 9. Документация

Документация обновляется при каждом важном решении:

- `docs/gdd.md` - дизайн игры.
- `docs/development_principles.md` - правила разработки.
- `docs/architecture_context.md` - быстрый вход для нового исполнителя.
- `docs/hotfixes.md` - журнал срочных исправлений.
- `docs/vertical_slice_spec.md` - scope первого среза.

Если решение влияет на архитектуру, баланс, сохранения или future extensibility, оно должно быть зафиксировано в документации до или вместе с кодом.
