---
phase: 1
plan: 2
wave: 1
---

# Plan 1.2: Регистрация source в Neo-tree и проверка загрузки

## Objective

Зарегистрировать `favorites` как source в neo-tree, чтобы `<leader>F` открывал плавающее окно Favorites, а вкладка появилась в winbar. На этом этапе дерево будет пустым (заглушка) — главное, что source загружается без ошибок.

## Context

- `.gsd/SPEC.md` — шорткаты, UI
- `.gsd/RESEARCH.md` — раздел 1 (Source Registration), раздел 2 (Source Contract)
- `lua/neo-tree-fav/init.lua` — source модуль (создан в Plan 1.1)
- Конфиг пользователя neo-tree (предоставлен в чате)
- Конфиг `lua/plugins/neo-tree-fav.lua` (lazy.nvim)

## Tasks

<task type="auto">
  <name>Настроить navigate() для отображения пустого дерева</name>
  <files>
    lua/neo-tree-fav/init.lua
    lua/neo-tree-fav/lib/items.lua
  </files>
  <action>
    1. В `lua/neo-tree-fav/lib/items.lua` реализовать `M.get_favorites(state)`:
       - Создать `context = file_items.create_context()`, `context.state = state`
       - Создать root: `file_items.create_item(context, state.path, "directory")`
       - Установить `root.name = "Favorites"`, `root.loaded = true`
       - `root.search_pattern = state.search_pattern`
       - `state.default_expanded_nodes = { root.path }`
       - `renderer.show_nodes({ root }, state)`
       - Шаблон 1:1 из `git_status/lib/items.lua`

    2. В `lua/neo-tree-fav/init.lua`:
       - `M.navigate()` вызывает `items.get_favorites(state)`
       - `M.setup()` вызывает `logger.init()`
       - `M.default_config` — задать renderers по умолчанию (file, directory)
  </action>
  <verify>
    В Neovim выполнить:
    :Neotree float favorites
    Должно открыться плавающее окно с заголовком "Favorites" и пустым деревом (только root).
  </verify>
  <done>
    - `:Neotree float favorites` открывает плавающее окно
    - Нет ошибок в `:messages`
    - Root-узел "Favorites" отображается
  </done>
</task>

<task type="checkpoint:human-verify">
  <name>Проверить интеграцию: winbar tab + shortcut</name>
  <files>нет изменений — инструкции для пользователя</files>
  <action>
    1. Предоставить пользователю изменения для его neo-tree конфига:
       - Добавить `"neo-tree-fav"` в `sources`
       - Добавить `{ source = "favorites" }` в `source_selector.sources`
       - Добавить keymap: `vim.keymap.set("n", "<leader>F", ":Neotree float favorites<CR>")`

    2. Пользователь применяет изменения и проверяет:
       - Вкладка "Favorites" в winbar
       - `<leader>F` открывает float с favorites
       - Переключение между tabs работает
  </action>
  <verify>
    Пользователь подтверждает:
    1. Вкладка видна в winbar
    2. `<leader>F` открывает float favorites
    3. Переключение вкладок не ломает другие source
  </verify>
  <done>
    - Favorites tab отображается в winbar рядом с filesystem, buffers, git_status
    - `<leader>F` открывает float
    - Нет регрессий в других source
  </done>
</task>

## Success Criteria

- [ ] `:Neotree float favorites` открывает плавающее окно без ошибок
- [ ] Root-узел "Favorites" отображается
- [ ] Вкладка Favorites видна в winbar
- [ ] `<leader>F` открывает float favorites
- [ ] Другие source (filesystem, buffers, git_status) продолжают работать
