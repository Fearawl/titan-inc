# Titan Inc - City Layout Authoring and Interception AI Design

Дата: 2026-05-03
Статус: дизайн утвержден пользователем в диалоге

## 1. Контекст

Текущая сцена города уже содержит базовую боевую симуляцию: спавн титанов и защитников, структуры с HP, repair, defense slots, дорожную линию, battle lane, HUD и data-driven контент на Godot `Resource`.

Главная проблема текущего состояния: расстановка важных объектов частично зашита в ресурсах и сцене, поэтому ее неудобно редактировать вручную в Godot. Кроме того, титаны слишком прямолинейно идут вперед, а защитники недостаточно активно реагируют на прорывы титанов в тыл.

Цель пакета - дать дизайнеру удобную сцену разметки уровня и усилить базовую логику столкновения армий:

- башни, стены, ворота, преграды, дома и spawn/defense points расставляются мышкой в 2D-редакторе Godot;
- игровые параметры типов остаются в custom `Resource`;
- титаны останавливаются у блокирующих destructible-объектов и разрушают их;
- защитники видят титанов на приличном радиусе, преследуют их и не позволяют спокойно уходить за линию обороны.

## 2. Scope

Входит в пакет:

- authoring-сцена для fantasy vertical slice layout;
- marker-сцены/скрипты для структур, спавна и охраняемых точек;
- runtime-сборщик layout, который читает маркеры и настраивает город;
- отказ от hardcoded `DEFENSE_POSITIONS` в пользу scene-authored defense markers;
- привязка структур к позициям из layout-сцены;
- улучшенное определение блокирующих структур перед титаном;
- усиленная логика defender detection/pursuit;
- документация по новой схеме разметки.

Не входит в пакет:

- полноценный editor plugin;
- финальный арт и tilemap уровня;
- сложный pathfinding по навмешу или сетке;
- hero/prestige;
- баланс 2-3-часового города;
- финальная tower climb animation.

## 3. Рассмотренные подходы

### Рекомендованный: обычная Godot-сцена с маркерами

Создать `FantasyCityLayout.tscn` как обычную сцену разметки. Внутри нее дизайнер вручную двигает marker nodes: структуры, точки спавна, охраняемые позиции, battle lane и road lane.

Плюсы:

- работает сразу в стандартном Godot editor;
- не требует editor plugin;
- удобно двигать объекты мышкой;
- хорошо сочетается с текущими runtime-системами;
- данные значений остаются в `Resource`, а сцена хранит размещение.

Минусы:

- layout становится сценовым контентом, поэтому нужен аккуратный runtime-сборщик;
- для массовой генерации городов позже может понадобиться отдельный `CityLayoutResource`.

### Альтернатива: все координаты в `.tres`

Можно хранить позиции структур и defense slots только в ресурсах.

Плюсы:

- максимально data-driven;
- легко версионировать как чистые данные.

Минусы:

- неудобно расставлять вручную;
- координаты приходится править числами;
- дизайнерский workflow становится медленным.

### Альтернатива: полноценный editor plugin

Можно сделать отдельный инструмент редактора с кастомными gizmo и инспекторами.

Плюсы:

- самый мощный вариант для будущего production pipeline.

Минусы:

- преждевременная сложность;
- сейчас важнее проверить core loop и поведение армий.

Выбор: обычная layout-сцена с marker nodes.

## 4. Архитектура

Новые элементы:

- `world/layout/city_layout.gd` - scene-owned контейнер layout-маркеров и точка входа для чтения разметки;
- `world/layout/structure_marker.gd` - маркер destructible-структуры с ссылкой на `StructureTypeResource`;
- `world/layout/spawn_point_marker.gd` - маркер spawn origin для титанов, защитников и ремонтников;
- `world/layout/defense_point_marker.gd` - маркер охраняемой позиции, который в runtime превращается в `DefenseSlotResource`-совместимые данные;
- `world/layout/fantasy_city_layout.tscn` - первая вручную редактируемая layout-сцена.

Existing runtime-сцена `CityScene` остается главной игровой сценой. Она получает ссылку на layout-сцену, читает маркеры в `_ready()` и настраивает:

- `BattleLane`;
- `RoadLane`;
- `TitanSpawnCoordinator`;
- `DefenderSpawnCoordinator`;
- `RepairCoordinator`;
- `DefenseSlotCoordinator`;
- spawned `DestructibleStructure`.

Ценности разделения:

- ресурсы описывают типы, баланс и правила;
- layout-сцена описывает размещение;
- runtime coordinators исполняют поведение;
- actor scripts остаются тонкими носителями визуала, HP и ссылок на контроллеры.

## 5. Authoring Markers

### Structure Marker

Поля:

- `structure_type: StructureTypeResource`;
- `marker_id: StringName`;
- `size_override: Vector2`;
- `blocks_movement_override`;
- `debug_color`.

Runtime:

- инстанцирует `DestructibleStructure`;
- передает type resource;
- передает stable runtime id из `marker_id` для save/load HP конкретного экземпляра;
- применяет позицию маркера как `global_position`;
- при необходимости применяет временный size override без мутации исходного resource.

### Spawn Point Marker

Типы:

- `TITAN`;
- `DEFENDER`;
- `REPAIR`.

Runtime:

- titan marker настраивает `TitanSpawnCoordinator.spawn_origin`;
- defender marker настраивает `DefenderSpawnCoordinator.spawn_origin`;
- repair marker настраивает `RepairCoordinator.spawn_origin`.

### Defense Point Marker

Поля:

- `slot_id: StringName`;
- `slot_type`;
- `capacity`;
- `range_multiplier`;
- `leash_radius`;
- `vision_radius`;
- `rear_guard_radius`;
- `allowed_defender_tags`;
- `anchor_structure_marker_id`.

Runtime:

- превращается в runtime `DefenseSlotResource`;
- сохраняет связь с anchor structure через стабильный id;
- передает расширенные параметры в `DefenderBehaviorController`.

## 6. Titan Interception Behavior

Титаны продолжают давить слева направо, но движение больше не должно игнорировать препятствия.

Правила:

- титан ищет ближайшую живую блокирующую структуру впереди;
- структура считается блокирующей, если ее X впереди титана и ее Y/размер пересекает боевой коридор титана;
- если структура в радиусе атаки, титан останавливается и бьет ее;
- fighter-титаны все еще могут остановиться для melee-защитника, если цель достижима;
- runner/armored игнорируют входящий melee-урон, но останавливаются у блокирующих структур;
- colossal сохраняет камень раз в 10 секунд и осадный melee у преграды.

Важное ограничение MVP: физическое столкновение через полноценные collision shape можно добавить позже. В этом пакете достаточно надежного target/intercept расчета по позициям и размеру destructible-структур.

## 7. Defender Detection and Pursuit

Защитник охраняет не абстрактную зону, а конкретную scene-authored точку.

Правила:

- defender бежит к assigned defense point;
- если видит титана в `vision_radius`, выбирает ближайшую валидную цель;
- если титан прошел левее охраняемой точки или находится за линией обороны, defender получает право преследовать его в расширенном `rear_guard_radius`;
- defender не должен бесконечно уходить влево, если рядом есть более опасный титан у его охраняемой позиции;
- если цель умерла, ушла слишком далеко или перестала быть угрозой для этой точки, defender возвращается на assigned point;
- ranged defender атакует с места, если титан в effective range;
- melee defender сближается и держит контакт.

Смысл: защитники не превращаются в зеркальную армию, бегущую до левого края, но и не дают титану безнаказанно пройти им за спину.

## 8. Data Flow

1. `CityScene` загружает `ContentCatalog` и layout scene.
2. `CityLayout` собирает дочерние маркеры в typed arrays.
3. `CityScene` спавнит структуры из `StructureMarker`.
4. `DefensePointMarker` превращаются в runtime slot resources и передаются в `DefenseSlotCoordinator`.
5. Spawn point markers настраивают координаты спавнеров.
6. Спавнеры создают юнитов как раньше.
7. Behavior controllers используют registry, road/battle lane и payload defense slot.
8. Combat and repair systems продолжают работать поверх уже зарегистрированных units/structures.

## 9. Save/Load

В сейве продолжаем хранить устойчивое состояние:

- валюты;
- army limits;
- run upgrades;
- HP структур по стабильному layout/runtime id;
- defeated heroes позже.

Layout-сцена не сохраняется как runtime-состояние. Это content/source of truth. При загрузке город пересобирается из layout markers, затем применяются сохраненные HP и run state.

Для совместимости текущий save/load может читать старые записи по `structure_type.id`, если новая запись по marker/runtime id еще отсутствует. Новые записи должны использовать `StructureMarker.marker_id`, чтобы несколько одинаковых домов или преград одного типа не перетирали HP друг друга.

## 10. Error Handling

Runtime должен мягко переживать неполную разметку:

- нет layout scene - использовать текущие fallback-настройки;
- marker без resource - пропустить и вывести `push_warning`;
- duplicate defense slot id - пропустить дубль и вывести warning;
- spawn marker отсутствует - оставить export value координатора;
- anchor structure не найден - slot остается ground slot без tower release behavior.

## 11. Testing and Acceptance

Пакет считается готовым, если:

- Godot headless editor открывает проект без parse errors;
- Godot headless run запускает `city_scene.tscn` без runtime errors;
- `fantasy_city_layout.tscn` можно открыть в Godot и вручную двигать маркеры;
- структуры появляются в местах marker nodes;
- defender/titan/repair spawn origins читаются из marker nodes;
- defense slots читаются из marker nodes;
- титаны останавливаются у преград и наносят им урон;
- защитники реагируют на титанов в радиусе видимости;
- защитники преследуют титанов, которые прошли за охраняемую точку;
- защитники возвращаются к точкам, когда угроза исчезает;
- документация и architecture context обновлены.

## 12. Implementation Order

1. Добавить marker scripts и `fantasy_city_layout.tscn`.
2. Подключить layout scene к `city_scene.tscn`.
3. Перевести spawn origins и defense slots на layout markers.
4. Перевести structure spawning на structure markers.
5. Усилить structure targeting для титанов.
6. Усилить defender detection/pursuit.
7. Обновить документацию.
8. Проверить headless editor/run и `git diff --check`.
