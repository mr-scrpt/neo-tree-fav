# RESEARCH.md — Neo-tree Source API Analysis

> **Date**: 2026-03-01
> **Phase**: 0 (Discovery)
> **Status**: Complete

## 1. Source Registration & Loading

**File**: `neo-tree/setup/init.lua:484-515`

Neo-tree загружает source-модули из списка `sources` в конфиге. Алгоритм:

1. Попытка `require("neo-tree.sources." .. source_name)` — внутренний namespace
2. Если не найдено: `require(source_name)` — внешний namespace (наш случай)
3. Из модуля берутся: `module.name`, `module.display_name`, `module.default_config`

**Для нашего плагина это значит:**
- В neo-tree config добавляем `sources = { "filesystem", "buffers", "git_status", "neo-tree-fav" }`
- Наш `lua/neo-tree-fav/init.lua` должен быть `require`-able как `"neo-tree-fav"`
- Он должен экспортировать: `name`, `display_name`, `setup()`, `navigate()`

**Дополнительные требования** (`setup/init.lua:537-538`):
```lua
source_default_config.components = module.components or require(mod_root .. ".components")
source_default_config.commands = module.commands or require(mod_root .. ".commands")
```
Нужно экспортировать `components` и `commands` таблицы, или иметь сабмодули `.components` и `.commands`.

---

## 2. Минимальный контракт Source

**File**: `sources/manager.lua:760-762`

```lua
---@class neotree.Source
---@field setup fun(config, global_config)
---@field navigate fun(state, path?, path_to_reveal?, callback?, async?)
```

Плюс: `name: string`, `display_name: string`.

---

## 3. Паттерн построения дерева (Reference: git_status)

**File**: `sources/git_status/lib/items.lua` — **50 строк**, идеальный образец.

```lua
local context = file_items.create_context()
context.state = state

-- 1. Создать root
local root = file_items.create_item(context, state.path, "directory")
root.name = vim.fn.fnamemodify(root.path, ":~")
root.loaded = true
root.search_pattern = state.search_pattern
context.folders[root.path] = root

-- 2. Добавить items
for path, _ in pairs(paths) do
  file_items.create_item(context, path, "file")
end

-- 3. Раскрыть все папки по умолчанию
state.default_expanded_nodes = {}
for id, _ in pairs(context.folders) do
  table.insert(state.default_expanded_nodes, id)
end

-- 4. Отсортировать и отрендерить
file_items.advanced_sort(root.children, state)
renderer.show_nodes({ root }, state)
```

**Ключевые моменты:**
- `file_items.create_item()` сам автоматически создаёт промежуточные папки через `set_parents()`
- `context.folders` содержит все папки, используется для `default_expanded_nodes`
- `renderer.show_nodes()` — единственная точка входа в рендерер

---

## 4. Структура FileItem (Node)

**File**: `sources/common/file-items.lua:127-144`

```lua
---@class neotree.FileItem
---@field id string          -- уникальный ID (обычно = path)
---@field name string        -- отображаемое имя (basename)
---@field type string        -- "file" | "directory"
---@field path string        -- полный путь
---@field loaded boolean     -- для папок: загружено ли содержимое
---@field children table     -- для папок: дочерние элементы
---@field search_pattern string?
---@field extra table?       -- доп. данные (bufnr, git_status)
---@field filtered_by table? -- фильтрация
```

`create_item()` использует `utils.split_path(path)` чтобы получить `parent_path` и `name`, затем вызывает `set_parents()` для автоматического создания дерева папок.

---

## 5. Раскрытие папок (fs_scan)

**File**: `sources/filesystem/lib/fs_scan.lua`

Для рекурсивного раскрытия реальных папок внутри избранного мы можем переиспользовать `fs_scan.get_items(state, parent_id, path_to_reveal, callback)`. Однако `fs_scan` сильно связан с `filesystem` source. 

**Альтернативный подход**: При раскрытии папки в favorites — использовать `uv.fs_scandir()` напрямую и вызывать `file_items.create_item()` для каждого файла. Это проще и не создаёт зависимость от filesystem source.

---

## 6. Фильтрация и поиск

Фильтрация в neo-tree работает через `search_pattern` в state и `filtered_items` config. Если мы используем стандартный `file_items.create_item()`, то:

- **Стандартные фильтры** (hidden files, gitignore) — работают автоматически
- **Fuzzy finder** — работает на основе `NuiTree` узлов, должен работать если items корректно созданы
- **Search pattern** — передаётся через `state.search_pattern`, должен работать

**Вывод:** Используя стандартный `file_items`, мы получаем совместимость с фильтрацией «из коробки».

---

## 7. Вывод коллизий

Для формата `name [relative/path/]`:
- Модифицировать `item.name` после вызова `create_item()`: `item.name = "domain [src/core]"`
- Это просто и будет работать с поиском (fuzzy finder ищет по `name`)
- `item.id` остаётся = `item.path` (уникальный), что гарантирует корректность дерева

---

## 8. Архитектура плагина (итого)

```
lua/neo-tree-fav/
├── init.lua          -- Source module: name, display_name, setup(), navigate()
├── commands.lua      -- Команды (open, delete, toggle_favorite, etc.)
├── components.lua    -- Компоненты (используем common, добавляем при необходимости)
└── lib/
    ├── items.lua     -- Построение дерева (по образцу git_status/lib/items.lua)
    ├── storage.lua   -- Чтение/запись JSON per-project
    └── logger.lua    -- Логирование
```
