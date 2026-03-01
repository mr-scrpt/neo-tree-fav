---
phase: 4
plan: 1
wave: 1
---

# Plan 4.1: Storage module + замена моков

## Objective

Реализовать `storage.lua` — модуль хранения списка избранных путей в per-project JSON.
Заменить в `items.lua` моковые данные на вызов `storage.get()`.
При пустом списке — показать message-node.

## Context

- `.gsd/SPEC.md` — Goals 2, 5 (toggle, persistence)
- `lua/neo-tree-fav/lib/items.lua` — текущий items builder (моки строки 15-29)
- `lua/neo-tree-fav/init.lua` — navigate, setup

## Tasks

<task type="auto">
  <name>Реализация storage.lua</name>
  <files>lua/neo-tree-fav/lib/storage.lua (NEW)</files>
  <action>
    Реализовать модуль хранения favorites:

    1. `M.get_storage_path()` → string
       - Путь: `vim.fn.stdpath("config") .. "/favorite-projects/" .. project_name .. "_" .. cwd_hash .. ".json"`
       - `project_name` = `vim.fn.fnamemodify(vim.fn.getcwd(), ":t")`
       - `cwd_hash` = первые 8 символов `vim.fn.sha256(vim.fn.getcwd())`
       - Создать директорию если не существует (`vim.fn.mkdir(..., "p")`)

    2. `M.load()` → string[]
       - Читает JSON файл, возвращает список абсолютных путей
       - Если файл не существует → пустой `{}`
       - vim.fn.json_decode + vim.fn.readfile

    3. `M.save(paths: string[])`
       - Записывает JSON: `vim.fn.writefile({vim.fn.json_encode(paths)}, storage_path)`

    4. `M.get()` → string[] — алиас для load()

    5. `M.add(path: string)` — добавляет если нет, сохраняет

    6. `M.remove(path: string)` — удаляет если есть, сохраняет

    7. `M.toggle(path: string)` → boolean — add/remove, возвращает true=added

    8. `M.has(path: string)` → boolean

    ИЗБЕГАТЬ:
    - Не кэшировать в памяти — всегда читать из файла (простота, корректность)
    - Не использовать async IO — файл маленький
  </action>
  <verify>
    В Neovim:
    `:lua print(vim.inspect(require("neo-tree-fav.lib.storage").get()))` → `{}`
    `:lua require("neo-tree-fav.lib.storage").add("/tmp/test")`
    `:lua print(vim.inspect(require("neo-tree-fav.lib.storage").get()))` → `{"/tmp/test"}`
    `:lua print(require("neo-tree-fav.lib.storage").has("/tmp/test"))` → `true`
    `:lua require("neo-tree-fav.lib.storage").remove("/tmp/test")`
    `:lua print(vim.inspect(require("neo-tree-fav.lib.storage").get()))` → `{}`
  </verify>
  <done>storage.lua реализован, все методы работают, JSON файл создаётся.</done>
</task>

<task type="auto">
  <name>items.lua: моки → storage.get()</name>
  <files>lua/neo-tree-fav/lib/items.lua</files>
  <action>
    1. Убрать `get_mock_favorites()` и `get_plugin_root()` (строки 15-29).
    2. В `get_favorites(state)`:
       - `local favorites = require("neo-tree-fav.lib.storage").get()`
       - Если `#favorites == 0` → создать message-node:
         ```lua
         root.children = {}
         local msg_item = {
           id = "favorites_empty_message",
           name = "Нет избранных. Нажмите F в проводнике для добавления.",
           type = "message",
         }
         table.insert(root.children, msg_item)
         ```
       - `resolve_name_collisions` использует `state.path` (CWD) как base_path
    3. Удалить `debug.getinfo` — пути теперь абсолютные из storage.

    ИЗБЕГАТЬ:
    - Менять логику flatten/reparenting — она работает
    - Менять scan_directory_recursive — она работает
  </action>
  <verify>
    `<leader>F` без добавленных favorites: показывает "Нет избранных...".
    `:lua require("neo-tree-fav.lib.storage").add(vim.fn.expand("%:p"))` → `<leader>F` → файл виден.
  </verify>
  <done>items.lua получает пути из storage, пустой список показывает message.</done>
</task>

<task type="checkpoint:human-verify">
  <name>Проверка динамического дерева</name>
  <action>
    1. `<leader>F` — пустое дерево с сообщением
    2. `:lua require("neo-tree-fav.lib.storage").add(vim.fn.expand("%:p"))` → `<leader>F` → файл виден
    3. `:lua require("neo-tree-fav.lib.storage").add("/path/to/directory")` → папка раскрывается
  </action>
  <done>Пользователь подтвердил</done>
</task>

## Success Criteria

- [ ] storage.lua — get/add/remove/toggle/has работают
- [ ] JSON файл создаётся в `~/.config/nvim/favorite-projects/`
- [ ] items.lua использует storage.get() вместо моков
- [ ] Пустое избранное — message-node
