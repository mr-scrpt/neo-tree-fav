# STATE.md — Project Memory

> **Last Updated**: 2026-03-01
> **Current Phase**: 3 (Динамическое дерево и Фильтрация)
> **Status**: Ready for planning

## Last Session Summary

Phase 2 (Ядро на моках) выполнена:
- Плоское дерево favorites из 5 mock-элементов
- Раскрытие папок стандартным toggle_node (loaded=true + children)
- Коллизии имён — `resolve_name_collisions()` готова
- Ключевой рефакторинг: убран кастомный toggle_directory, commands.lua минимальный
- Баг-фикс: CWD ненадёжен (bind_to_cwd), используем debug.getinfo

## Findings

- `fuzzy_finder` (`/`), `filter` (`f`), `fuzzy_sorter` (`#`) — НЕ стандартные команды, а filesystem-специфичные
- Buffers, git_status, document_symbols тоже не имеют поиска
- Для Phase 3 нужна своя обёртка filter.lua (~50 строк)

## Next Steps

1. `/plan 3` — Phase 3: Динамическое дерево, фильтрация, поиск

## Blockers

- Нет
