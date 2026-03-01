---
phase: 3
plan: 2
wave: 2
---

# Plan 3.2: Фильтрация и поиск

## Objective

Добавить поддержку fuzzy_finder (`/`), filter (`f`) и fuzzy_sorter (`#`) в favorites source.
Эти команды определены только в `filesystem/commands.lua` и используют `filesystem/lib/filter.lua`,
который жёстко привязан к `fs._navigate_internal()` и `fs.reset_search()`.

Решение: написать свой тонкий `lib/filter.lua`, который переиспользует `common.filters`
(setup_hooks, setup_mappings) и `nui.input` для UI, но вызывает наш `navigate()`.

## Context

- `lua/neo-tree-fav/init.lua` — source contract, navigate()
- `lua/neo-tree-fav/commands.lua` — текущие команды (только common)
- `neo-tree/sources/filesystem/lib/filter.lua` — референсная реализация (242 строки)
- `neo-tree/sources/common/filters.lua` — переиспользуемые хуки и маппинги
- `neo-tree/sources/filesystem/commands.lua:86-125` — filter/fuzzy команды

## Tasks

<task type="auto">
  <name>lib/filter.lua — обёртка поиска для favorites</name>
  <files>lua/neo-tree-fav/lib/filter.lua</files>
  <action>
    Скопировать структуру из `filesystem/lib/filter.lua`, но упростить:

    1. `M.show_filter(state, search_as_you_type, fuzzy_finder_mode, use_fzy, keep_filter_on_submit)` —
       та же сигнатура что и filesystem.
    2. UI: переиспользовать `nui.input`, `popups.popup_options` — как в оригинале.
    3. `on_change` callback: устанавливает `state.search_pattern`, вызывает
       `require("neo-tree-fav").navigate(state)` (вместо `fs._navigate_internal`).
    4. `on_submit`: при пустом — reset search (обнулить `state.search_pattern`, navigate).
    5. `M.reset_search(state, refresh)` — обнуляет state поля, вызывает navigate.
    6. Переиспользовать `common_filter.setup_hooks()` и `setup_mappings()` для клавиш навигации в popup.

    КЛЮЧЕВЫЕ ОТЛИЧИЯ от filesystem/lib/filter.lua:
    - Нет `fs.reset_search` → свой `M.reset_search`
    - Нет `fs._navigate_internal` → `fav.navigate(state)`
    - Нет `state.force_open_folders` (мы не используем это)
    - Debounce key: "favorites_filter" (не "filesystem_filter")
  </action>
  <verify>
    Файл создан, require без ошибок:
    `:lua require("neo-tree-fav.lib.filter")`
  </verify>
  <done>lib/filter.lua реализован, переиспользует common_filter</done>
</task>

<task type="auto">
  <name>commands.lua: добавить filter/fuzzy команды и маппинги</name>
  <files>
    lua/neo-tree-fav/commands.lua
    lua/neo-tree-fav/init.lua
  </files>
  <action>
    1. В `commands.lua` добавить:
       - `M.filter_as_you_type(state)` → `filter.show_filter(state, true, false, false, false)`
       - `M.filter_on_submit(state)` → `filter.show_filter(state, false, false, false, true)`
       - `M.fuzzy_finder(state)` → `filter.show_filter(state, true, true, false, false)`
       - `M.fuzzy_sorter(state)` → `filter.show_filter(state, true, true, true, false)`
       - `M.clear_filter(state)` → `filter.reset_search(state, true)`

    2. В `init.lua` → `default_config.window.mappings`:
       ```lua
       ["/"] = "fuzzy_finder",
       ["f"] = "filter_on_submit",
       ["#"] = "fuzzy_sorter",
       ["<C-x>"] = "clear_filter",
       ```

    3. В `init.lua` добавить `M.reset_search` = функция сброса поиска (обнулить
       `state.search_pattern`, `state.fuzzy_finder_mode`, вызвать navigate).

    ИЗБЕГАТЬ:
    - Не копировать navigate_up, set_root, toggle_hidden — это filesystem-specific
  </action>
  <verify>
    В Neovim открыть `<leader>F`, нажать `/` — должна появиться строка "Filter:"
    внизу окна. Ввод текста должен фильтровать дерево в реальном времени.
    `f` — строка "Search:", фильтрация по submit (Enter).
    `#` — fuzzy sorter.
  </verify>
  <done>
    Маппинги `/`, `f`, `#`, `<C-x>` работают в favorites source.
    Fuzzy finder фильтрует дерево в реальном времени.
  </done>
</task>

<task type="checkpoint:human-verify">
  <name>Визуальная проверка поиска и фильтрации</name>
  <action>
    Пользователь проверяет:
    1. `<leader>F` → `/` → ввод "aggr" → видит только aggregate-root.ts
    2. `<leader>F` → `f` → ввод "schema" → Enter → видит schema.prisma
    3. `<C-x>` — сброс фильтра, видит всё дерево
  </action>
  <done>Пользователь подтвердил</done>
</task>

## Success Criteria

- [ ] `/` открывает fuzzy finder в favorites
- [ ] `f` открывает filter на submit
- [ ] `#` открывает fuzzy sorter
- [ ] `<C-x>` сбрасывает фильтр
- [ ] Фильтрация корректно работает с виртуальными узлами
