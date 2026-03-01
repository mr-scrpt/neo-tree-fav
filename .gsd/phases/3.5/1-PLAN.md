---
phase: 3.5
plan: 1
wave: 1
---

# Plan 3.5.1: Audit + документирование реиспользования neo-tree internals

## Objective

Провести финальный audit текущего `lib/filter.lua` и `commands.lua`:
- Задокументировать что именно переиспользуется из neo-tree
- Задокументировать что написано кастомно и ПОЧЕМУ
- Добавить ссылки на оригинальные модули для сопровождения
- Убрать любой лишний код если найдётся

## Context

- `.gsd/phases/3.5/RESEARCH.md` — результаты анализа
- `lua/neo-tree-fav/lib/filter.lua` — текущий filter module (230 строк)
- `lua/neo-tree-fav/commands.lua` — текущие команды (44 строки)
- `neo-tree/sources/common/filters/init.lua` — generic filter
- `neo-tree/sources/filesystem/lib/filter.lua` — filesystem filter (образец)
- `neo-tree/sources/filesystem/init.lua:202-248` — fs.reset_search (образец)

## Tasks

<task type="auto">
  <name>Audit и cleanup lib/filter.lua</name>
  <files>lua/neo-tree-fav/lib/filter.lua</files>
  <action>
    1. Добавить doc-comment в начало файла с описанием архитектуры:
       - Что переиспользуется: `fzy` (scoring), `setup_hooks` + `setup_mappings` (keybinds)
       - Что кастомное: `show_filtered_tree` (clone+filter), `reset_search` (open_file/navigate)
       - Почему нельзя использовать common/filters.show_filter:
         a) reset_filter hardcoded filter_external.cancel()
         b) reset_filter не делает open_file на Enter
         c) setup_mappings читает config.filesystem
       - Ссылки на оригиналы: common/filters/init.lua, filesystem/init.lua:202-248

    2. Проверить: есть ли в filter.lua мёртвый код или дублирование.
       Удалить если найдётся.

    3. Проверить: правильно ли работает `on_change` для пустого значения (backspace до 0)
       Сравнить с filesystem/lib/filter.lua:144-154.
  </action>
  <verify>`:lua require("neo-tree-fav.lib.filter")` — без ошибок. Filter работает.</verify>
  <done>lib/filter.lua задокументирован, мёртвый код удалён.</done>
</task>

<task type="auto">
  <name>Audit commands.lua</name>
  <files>lua/neo-tree-fav/commands.lua</files>
  <action>
    1. Добавить doc-comment с описанием:
       - `cc._add_common_commands(M)` — open, toggle_node, etc. (из neo-tree)
       - filter/fuzzy — из нашего lib/filter.lua (и почему не из common)

    2. Проверить: нет ли неиспользуемых переменных (redraw, refresh если не используются).
  </action>
  <verify>`:lua require("neo-tree-fav.commands")` — без ошибок.</verify>
  <done>commands.lua задокументирован, лишние переменные удалены.</done>
</task>

<task type="checkpoint:decision">
  <name>Решение: оставить как есть или рефакторить</name>
  <action>
    Представить пользователю findings:
    - Что переиспользуется (fzy, setup_hooks, setup_mappings, _add_common_commands)
    - Что кастомное и почему (show_filtered_tree, reset_search)
    - Вердикт: текущий подход оптимален / нужен рефакторинг
  </action>
  <done>Пользователь подтвердил решение</done>
</task>

## Success Criteria

- [ ] lib/filter.lua задокументирован с ссылками на оригиналы
- [ ] Мёртвый код удалён
- [ ] commands.lua задокументирован
- [ ] Пользователь принял решение по архитектуре
