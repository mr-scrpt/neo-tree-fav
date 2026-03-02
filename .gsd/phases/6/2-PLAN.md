---
phase: 6
plan: 2
wave: 2
---

# Plan 6.2: Jump-between-matches и UX polish

## Objective
Добавить навигацию Tab/S-Tab по файлам в фильтре (пропуская папки) и финальную полировку UX.

## Context
- .gsd/SPEC.md
- lua/neo-tree-fav/lib/filter.lua
- lua/neo-tree-fav/lib/items.lua
- lua/neo-tree-fav/init.lua

## Tasks

<task type="auto">
  <name>Jump between file matches (Tab/S-Tab)</name>
  <files>lua/neo-tree-fav/lib/filter.lua</files>
  <action>
    В show_filter добавить в cmds:
    - `move_cursor_to_next_file` — использует renderer.select_nodes(state.tree, is_file)
      для получения списка файловых узлов, находит текущую позицию, прыгает к следующему файлу
    - `move_cursor_to_prev_file` — аналогично, но назад

    Алгоритм:
    1. Получить все файловые узлы: `renderer.select_nodes(tree, node.type=="file")`
    2. Получить текущий узел: `state.tree:get_node()`
    3. Найти текущий в списке -> взять следующий/предыдущий
    4. `renderer.focus_node(state, next_file:get_id(), true)`

    Замаппить в filter через input:map:
    - `<Tab>` → move_cursor_to_next_file
    - `<S-Tab>` → move_cursor_to_prev_file

    НЕ использовать fuzzy_finder_mappings (это глобальный конфиг).
    Маппить локально через input:map после setup_mappings.
  </action>
  <verify>
    1. Открыть favorites с несколькими файлами в разных папках
    2. `/` → ввести запрос → Tab прыгает к следующему файлу, пропуская папки
    3. S-Tab — назад
  </verify>
  <done>Tab/S-Tab прыгает между файлами, пропуская папки в фильтрованном дереве</done>
</task>

<task type="auto">
  <name>select_first_file callback</name>
  <files>lua/neo-tree-fav/lib/items.lua</files>
  <action>
    В items.get_favorites, после renderer.show_nodes и при активном search_pattern:
    - Использовать renderer.select_nodes(state.tree, is_file, 1) для фокуса на первый файл
      (как в filesystem/lib/filter.lua:select_first_file)
    - Это заменяет текущий focus_id по fzy score — стандартный подход filesystem

    Убедиться что фокус ставится на ФАЙЛ, а не на папку-родителя.
  </action>
  <verify>
    1. При поиске фокус автоматически на первом файле, не на папке
  </verify>
  <done>Фокус после фильтрации всегда на файле, не на директории</done>
</task>

<task type="auto">
  <name>UX: уведомления и README</name>
  <files>README.md</files>
  <action>
    Создать README.md с:
    - Описание плагина
    - Установка (lazy.nvim)
    - Маппинги: `<leader>F` (float), `F` (toggle в filesystem), `/` (поиск)
    - Маппинги в favorites: `F` (remove), `X` (clean missing), `Tab/S-Tab` (jump files)
    - Конфигурация (neo-tree sources)
    - Зависимости (neo-tree.nvim v3.x, nui.nvim)
  </action>
  <verify>cat README.md — содержит все секции</verify>
  <done>README.md создан с полной документацией</done>
</task>

## Success Criteria
- [ ] Tab/S-Tab прыгает между файлами в фильтре
- [ ] Фокус после фильтрации на первом файле
- [ ] README.md с полной документацией
