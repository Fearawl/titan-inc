# Titan Inc - Vertical Slice Spec

Дата фиксации: 2026-04-27  
Статус: утвержденный scope первого вертикального среза

## 1. Цель среза

Создать playable foundation для `Titan Inc`: idle/incremental 2D pixel-art боя, где армия титанов непрерывно давит слева направо, защитники удерживают позиции, строения разрушаются и ремонтируются, а игрок усиливает армию через экономику.

Первый город должен занимать примерно 2-3 часа.

## 2. Участки города

В срез входят:

1. Пригород.
2. Башни.
3. Стена.

Будущая полная структура города может включать пригород, сторожевые башни, первые врата, город, вторые врата, город, третьи врата и замок. В срезе делаем только первые три участка.

## 3. Runtime loop

1. Купленные лимиты титанов определяют доступную армию.
2. Титаны спавнятся слева и бегут вправо к стене.
3. Защитники спавнятся справа, получают defense positions и удерживают их.
4. Титаны ломают препятствия, дома, башни, ворота и стены.
5. Защитники атакуют титанов и могут отбросить давление армии назад.
6. При удержании позиций ремонтники из тыла чинят повреждения.
7. За убийства и разрушения начисляются ресурсы.
8. Игрок покупает лимиты титанов и upgrades.
9. После героя открывается prestige-окно.

## 4. Титаны в срезе

Все пять типов доступны для покупки лимита в первом срезе:

| Тип | Описание |
| --- | --- |
| Мелкий | Мало HP, малый урон, средняя скорость |
| Бегун | Мало HP, средний урон, высокая скорость |
| Базовый | Средние HP, средний урон, средняя скорость |
| Бронированный | Очень много HP, средний урон, низкая скорость |
| Колоссальный | Очень много HP, огромный урон, низкая скорость, дальняя атака камнями |

Правила:

- До 100 юнитов каждого типа.
- Respawn cooldown по умолчанию 5 секунд.
- Покупка увеличивает лимит армии типа.
- Уровни upgrades общие для типа.
- У каждого юнита есть HP bar.

## 5. Защитники в срезе

Типы:

- Крестьянин.
- Лучник.
- Воин.
- Рыцарь.
- Арбалетчик.
- Всадник.
- Герой.

Правила:

- Спавн справа.
- Лимиты по типам или волнам.
- Defense position назначается при создании.
- Юниты удерживают позицию, а не бегут до левой границы.
- Башенные юниты могут заходить внутрь башни и появляться наверху.
- При разрушении башни защитники сверху падают и получают damage.

## 6. Строения

Все строения и препятствия имеют HP.

В срезе нужны:

- дома пригорода;
- малые ограждения или препятствия;
- две башни участка башен;
- ворота;
- две башни стены;
- стена как главный объект.

Башни и стены могут иметь garrison positions.

Разрушение должно поддерживать debris VFX и collapse damage.

## 7. Ремонт

Ремонтники появляются, когда защитники удерживают позиции, а рядом есть damaged repairable structure.

Базовые правила:

- ремонт постепенный;
- ремонт можно прервать;
- ремонтники являются уязвимыми юнитами;
- полностью разрушенный ключевой objective по умолчанию считается пройденным и не восстанавливается.

## 8. Ресурсы и покупки

Валюты:

- meat;
- stone;
- metal;
- hero_heart.

Стартовые цены:

| Тип | Цена |
| --- | --- |
| Мелкий | 10 meat за второго |
| Бегун | 100 meat |
| Базовый | 250 meat + 10 stone |
| Бронированный | 1000 meat + 10 metal |
| Колоссальный | 10000 meat + 1000 stone + 1000 metal |

Базовая формула роста цены: `new_price = previous_price * 2`.

## 9. Cursor boost

Курсор постоянно усиливает титанов в радиусе.

В первом срезе базовый эффект:

- множитель урона к итоговому damage.

Позже через meta-upgrades:

- attack speed;
- movement speed;
- destruction radius;
- cursor radius.

Радиус эффекта должен отображаться.

## 10. Prestige и meta

Prestige доступен после первого убийства героя.

Первый meta-экран:

- табличный вид;
- без связей;
- без сложных взаимозависимостей;
- данные уже через `MetaUpgradeResource`.

## 11. Save/load

С первого implementation package должны существовать:

- `GameState`;
- `SaveService`;
- `save_version`;
- сохранение валют;
- сохранение купленных лимитов армии;
- сохранение уровней upgrades;
- сохранение текущего города/зоны;
- сохранение HP важных поврежденных структур;
- сохранение hero/prestige состояния;
- сохранение meta-upgrades.

## 12. Acceptance criteria первой технической версии

Первая техническая версия считается полезной, если:

- запускается Godot-проект;
- титан спавнится, движется вправо и атакует;
- защитник спавнится, занимает позицию и атакует;
- структура имеет HP и разрушается;
- ресурс начисляется за убийство или разрушение;
- лимит титана можно купить через временный UI/debug action;
- состояние можно сохранить и загрузить;
- документация обновлена по фактическим решениям.

Финальный UI, арт и баланс 2-3 часов не являются требованием самой первой технической версии, но являются целью вертикального среза.

## Foundation Package Status

Implemented in the first technical package:

- Godot project startup.
- Autoload `SignalBus`, `GameState`, and `SaveService`.
- Custom Resource classes for core combat/economy/content data.
- Initial content resources for titans, defenders, structures, and zones.
- Debug city scene with simple visual actors.
- Continuous titan and defender spawning.
- HP, damage, destruction, drops, and basic repair workers.
- Debug resource granting and army-limit purchases.
- JSON save/load for core `GameState`.

Battlefield Behavior implemented through Task 8:

- Central road lane and randomized titan lane spawning.
- Data-driven titan and defender behavior profiles with runtime controllers.
- Fighter, runner, armored, and colossal titan behavior, including colossal boulder projectile siege attacks.
- Defender defense slots, including tower garrison slots with `range_multiplier = 2.0`.
- Archer projectile arrows and range calculation through `DefenderBehaviorController.effective_attack_range()`.
- Tower destruction handling that releases defenders occupying slots anchored to the destroyed structure, applies one fall-damage hit, clears the tower slot assignment, and returns them to road-lane fallback behavior.

Remaining vertical-slice work:

- Final UI/UX.
- Real pixel art and animation.
- Full balance pass for 2-3 hour first city pacing.
- Cursor boost visualization and meta-upgrade table.
- More complete tower climbing animation, formation polish, collapse debris, and zone completion polish.
