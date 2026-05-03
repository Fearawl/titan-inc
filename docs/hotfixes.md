# Titan Inc - Hotfixes

Дата создания: 2026-04-27

Этот файл фиксирует срочные исправления, которые меняют поведение проекта, обходят критические проблемы или временно нарушают обычные архитектурные правила.

Формат записи:

```text
## YYYY-MM-DD - Краткое название

- Причина:
- Изменение:
- Риск:
- Что нужно пересмотреть позже:
```

## 2026-05-03 - Structure HP runtime ids

- Reason: manual layout authoring can place multiple structures that share one `StructureTypeResource`, so saving HP only by `structure_type.id` can make instances overwrite each other.
- Change: `DestructibleStructure` now writes HP by stable layout/runtime id from `StructureMarker.marker_id`. Old `structure_type.id` keys are still read as a compatibility fallback.
- Risk: existing saves may contain old structure HP keys; the fallback keeps them readable until a new save writes marker ids.
- Review later: when multiple cities are added, city id should become part of the structure runtime save key.

## 2026-04-27 - Foundation package

- Причина: первый технический пакет создан по утвержденной архитектуре.
- Изменение: hotfix-исправлений нет.
- Риск: отсутствует.
- Что нужно пересмотреть позже: файл остается журналом для будущих срочных исправлений.
