---
phase: 3
plan: 1
wave: 1
---

# Plan 3.1: Динамическое дерево (замена моков на storage API)

## Objective

Заменить захардкоженный `get_mock_favorites()` в `items.lua` на вызов `storage.get()`,
который возвращает список абсолютных путей из per-project JSON-файла.
На этом этапе storage реализует минимальный API: `get()`, `add()`, `remove()`, `toggle()`.
Файл JSON создаётся/читается из `~/.config/nvim/favorite-projects/`.

## Context

- `.gsd/SPEC.md` — Goals 2, 3, 5
- `lua/neo-tree-fav/lib/items.lua` — текущий items builder (моки на строках 20-29)
- `lua/neo-tree-fav/lib/storage.lua` — заглушка, заменить реальной реализацией
- `lua/neo-tree-fav/init.lua` — source contract (navigate вызывает items.get_favorites)

## Tasks

<task type="auto">
  <name>Реализация storage.lua</name>
  <files>lua/neo-tree-fav/lib/storage.lua</files>
  <action>
    Реализовать модуль хранения favorites:

    1. `M.get_storage_path()` — вычисляет путь к JSON-файлу:
       `~/.config/nvim/favorite-projects/{project_name}_{cwd_hash}.json`
       - `project_name` = basename CWD
       - `cwd_hash` = первые 8 символов SHA256 от CWD (для уникальности)
       - Использовать `vim.fn.stdpath("config")` для base path
       - Создавать директорию `favorite-projects/` если не существует
    2. `M.get()` → string[] — читает JSON, возвращает список абсолютных путей.
       Если файл не существует — возвращает пустой `{}`.
    3. `M.add(path)` — добавляет абсолютный путь (если ещё нет), сохраняет.
    4. `M.remove(path)` — удаляет путь (если есть), сохраняет.
    5. `M.toggle(path)` → boolean — add если нет, remove если есть.
       Возвращает true если добавлен, false если удалён.
    6. `M.has(path)` → boolean — проверка наличия.
    7. Внутренний `save(paths)` и `load()` через `vim.fn.json_encode`/`json_decode`.

    ИЗБЕГАТЬ:
    - Использовать vim.fn.getcwd() ТОЛЬКО для вычисления имени проекта (не для путей items)
    - Не кэшировать данные в памяти — всегда читать из файла (Phase 5 оптимизирует)
  </action>
  <verify>
    В Neovim: `:lua print(vim.inspect(require("neo-tree-fav.lib.storage").get()))`
    Должен вернуть `{}` (пустой список) без ошибок.
    `:lua require("neo-tree-fav.lib.storage").add("/tmp/test"); print(vim.inspect(require("neo-tree-fav.lib.storage").get()))`
    Должен вернуть `{"/tmp/test"}`.
  </verify>
  <done>
    storage.lua реализован: get/add/remove/toggle/has работают.
    JSON-файл создаётся в ~/.config/nvim/favorite-projects/.
  </done>
</task>

<task type="auto">
  <name>items.lua: замена моков на storage.get()</name>
  <files>lua/neo-tree-fav/lib/items.lua</files>
  <action>
    1. Убрать `get_mock_favorites()` и `get_plugin_root()`.
    2. В `get_favorites(state)`:
       - Вызвать `require("neo-tree-fav.lib.storage").get()` вместо mock.
       - Если список пуст — показать message-node "Нет избранных. Нажмите F в проводнике."
       - `resolve_name_collisions` использует `state.path` (CWD) как base_path.
    3. Удалить привязку к `debug.getinfo` — пути теперь абсолютные из storage.

    ИЗБЕГАТЬ:
    - Менять логику flatten/рeparenting — она работает.
    - Менять scan_directory_recursive — она работает.
  </action>
  <verify>
    `<leader>F` без добавленных favorites: показывает message "Нет избранных".
    После `:lua require("neo-tree-fav.lib.storage").add(vim.fn.expand("%:p"))` и повторного `<leader>F`:
    текущий файл появляется в дереве.
  </verify>
  <done>
    items.lua получает paths из storage.get().
    Пустой список отображает message-node.
    Добавленные пути корректно рендерятся.
  </done>
</task>

<task type="checkpoint:human-verify">
  <name>Визуальная проверка динамического дерева</name>
  <action>
    Пользователь проверяет:
    1. `<leader>F` — пустое дерево с сообщением
    2. Добавить файл через storage.add → `<leader>F` → файл виден
    3. Добавить папку → папка раскрывается
  </action>
  <done>Пользователь подтвердил</done>
</task>

## Success Criteria

- [ ] `storage.lua` — get/add/remove/toggle/has работают с JSON per-project
- [ ] `items.lua` — использует storage.get() вместо моков
- [ ] Пустое избранное показывает message-node
- [ ] Добавленные элементы корректно рендерятся
