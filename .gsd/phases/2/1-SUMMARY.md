---
phase: 2
plan: 1
status: complete
---

# Summary 2.1: Мок-данные и рендеринг

## Что сделано

- `items.lua`: плоский верхний уровень через create_item + reparenting
  - 5 mock-файлов/папок из `my-project/`
  - Путь через `debug.getinfo` (не CWD — баг с `bind_to_cwd`)
  - Стандартный `toggle_node` работает — dirs `loaded=true` + children
- `commands.lua`: минимальный — только `_add_common_commands(M)`
- `init.lua`: убран кастомный `toggle_directory`

## Архитектурное решение

Плоское дерево: `create_item` строит полную иерархию через `set_parents`, затем `root.children` заменяется на только избранные items. Промежуточные папки отбрасываются, но `.children` каждого item сохраняется.

## Верификация ✓

- Плоское дерево с 5 элементами
- Папки раскрываются/сворачиваются стандартным `<space>`
- Файлы открываются через `<Enter>`
- Иконки корректны
