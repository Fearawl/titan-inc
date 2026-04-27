# Titan Inc - Architecture Context

Дата фиксации: 2026-04-27  
Цель: быстрый вход нового исполнителя в проект

## 1. Текущее состояние

Репозиторий стартует с документационной базы. Godot project skeleton и игровые системы еще не созданы.

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

После ревью документации нужно перейти к implementation plan. Первый пакет разработки:

1. Создать Godot project skeleton.
2. Добавить autoload-сервисы.
3. Добавить core Resource-классы.
4. Создать стартовый content pack.
5. Реализовать простой save/load.
6. Реализовать базовый спавн титанов и защитников.
7. Реализовать HP/damage/destruction.
8. Реализовать горизонтальное движение и defense positions.
9. Реализовать начисление ресурсов и покупку лимитов.
10. Поддерживать документацию по факту изменений.

Перед началом кода нужен отдельный implementation plan.
