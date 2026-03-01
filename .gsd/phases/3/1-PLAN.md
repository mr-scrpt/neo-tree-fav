---
phase: 3
plan: 1
wave: 1
---

# Plan 3.1: Фильтрация и поиск для favorites source

## Objective

Добавить поддержку fuzzy_finder (`/`), filter_on_submit (`f`), fuzzy_sorter (`#`)
в favorites source. Эти команды — НЕ часть common commands, а определены только в
`filesystem/commands.lua` через `filesystem/lib/filter.lua`, который жёстко привязан
к `fs._navigate_internal()` и `fs.reset_search()`.

Решение: написать свой `lib/filter.lua`, который переиспользует `common.filters`
(setup_hooks, setup_mappings) и `nui.input`, но вызывает наш `navigate()`.
Тестируем на моках — storage ещё не реализован.

## Context

- `lua/neo-tree-fav/init.lua` — source contract, navigate()
- `lua/neo-tree-fav/commands.lua` — текущие команды (только common)
- `neo-tree/sources/filesystem/lib/filter.lua` — референсная реализация
- `neo-tree/sources/common/filters.lua` — переиспользуемые хуки и маппинги
- `neo-tree/sources/filesystem/commands.lua:86-125` — filter/fuzzy команды
- `lua/neo-tree-fav/lib/items.lua` — items builder (search_pattern передаётся в root)

## Tasks

<task type="auto">
  <name>lib/filter.lua — обёртка поиска для favorites</name>
  <files>lua/neo-tree-fav/lib/filter.lua (NEW)</files>
  <action>
    Скопировать структуру из `filesystem/lib/filter.lua`, упростить:

    1. `M.show_filter(state, search_as_you_type, fuzzy_finder_mode, use_fzy, keep_filter_on_submit)` —
       та же сигнатура что и filesystem.
    2. UI: переиспользовать `nui.input`, `popups.popup_options`.
    3. `on_change`: устанавливает `state.search_pattern`, debounce-вызов
       `require("neo-tree-fav").navigate(state)`.
    4. `on_submit`: пустое — reset, иначе `state.search_pattern = value`.
    5. `M.reset_search(state, refresh)` — обнуляет search/fuzzy поля, вызывает navigate.
    6. Переиспользовать `common_filter.setup_hooks()` и `setup_mappings()`.

    КЛЮЧЕВЫЕ ОТЛИЧИЯ от filesystem/lib/filter.lua:
    - `fav.navigate(state)` вместо `fs._navigate_internal(state)`
    - `M.reset_search` вместо `fs.reset_search`
    - Debounce key: `"favorites_filter"`
    - Нет `state.force_open_folders`
  </action>
  <verify>`:lua require("neo-tree-fav.lib.filter")` — без ошибок</verify>
  <done>lib/filter.lua создан и загружается без ошибок</done>
</task>

<task type="auto">
  <name>commands.lua + init.lua: команды и маппинги</name>
  <files>
    lua/neo-tree-fav/commands.lua
    lua/neo-tree-fav/init.lua
  </files>
  <action>
    1. В `commands.lua` добавить:
       ```lua
       local filter = require("neo-tree-fav.lib.filter")
       M.filter_as_you_type = function(state)
         filter.show_filter(state, true, false, false, false)
       end
       M.filter_on_submit = function(state)
         filter.show_filter(state, false, false, false, true)
       end
       M.fuzzy_finder = function(state)
         filter.show_filter(state, true, true, false, false)
       end
       M.fuzzy_sorter = function(state)
         filter.show_filter(state, true, true, true, false)
       end
       M.clear_filter = function(state)
         filter.reset_search(state, true)
       end
       ```

    2. В `init.lua` → `default_config.window.mappings` добавить:
       ```lua
       ["/"] = "fuzzy_finder",
       ["f"] = "filter_on_submit",
       ["#"] = "fuzzy_sorter",
       ["<C-x>"] = "clear_filter",
       ```

    3. В `init.lua` добавить `M.reset_search(state, refresh)` — вызывается
       из filter.lua (по аналогии с `fs.reset_search`).
  </action>
  <verify>
    `<leader>F` → `/` — появляется строка "Filter:" внизу окна.
    Ввод "aggr" — дерево фильтруется в реальном времени.
  </verify>
  <done>Маппинги `/`, `f`, `#`, `<C-x>` работают в favorites</done>
</task>

<task type="checkpoint:human-verify">
  <name>Визуальная проверка поиска и фильтрации</name>
  <action>
    1. `<leader>F` → `/` → ввод "aggr" → показывает aggregate-root.ts
    2. `<leader>F` → `f` → "schema" → Enter → показывает schema.prisma
    3. `<C-x>` — сброс фильтра, видит всё дерево
    4. `#` — fuzzy sorter работает
  </action>
  <done>Пользователь подтвердил работу фильтрации</done>
</task>

## Success Criteria

- [ ] `/` открывает fuzzy finder в favorites
- [ ] `f` открывает filter на submit
- [ ] `#` открывает fuzzy sorter
- [ ] `<C-x>` сбрасывает фильтр
- [ ] Фильтрация корректно работает с виртуальными узлами на моках
