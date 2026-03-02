---
phase: 10
plan: 1
wave: 1
---

# Plan 10.1: storage_mode — local vs global

## Objective
Добавить опцию `storage_mode` в config: `"local"` хранит `.neo-tree-fav.json` в корне
проекта (cwd), `"global"` (default) — централизованно в `storage_dir`.

## Context
- lua/neo-tree-fav/lib/config.lua
- lua/neo-tree-fav/lib/storage.lua
- README.md

## Tasks

<task type="auto">
  <name>Добавить storage_mode в config и обновить storage.lua</name>
  <files>
    lua/neo-tree-fav/lib/config.lua
    lua/neo-tree-fav/lib/storage.lua
  </files>
  <action>
    1. config.lua — добавить:
       ```lua
       storage_mode = "global",  -- "local" | "global"
       ```

    2. storage.lua — обновить `get_storage_path()`:
       - Если `storage_mode == "local"`:
         - Файл: `cwd .. "/.neo-tree-fav.json"`
         - Без хеша, без project_name — один файл на проект
       - Если `storage_mode == "global"`:
         - Оставить текущую логику: `storage_dir/{project_name}_{hash}.json`

    ВАЖНО: при `local` НЕ создавать поддиректории,
    просто .neo-tree-fav.json в корне. Добавить `.neo-tree-fav.json`
    в дефолтный .gitignore проекта (рекомендация в README).
  </action>
  <verify>grep -n "storage_mode" lua/neo-tree-fav/lib/config.lua lua/neo-tree-fav/lib/storage.lua</verify>
  <done>storage_mode работает, get_storage_path возвращает разный путь для local/global</done>
</task>

<task type="auto">
  <name>Обновить README</name>
  <files>README.md</files>
  <action>
    Добавить описание `storage_mode` в секцию Configuration:
    ```lua
    storage_mode = "global",  -- "local" = .neo-tree-fav.json в корне проекта
                              -- "global" = централизованно в storage_dir
    ```
    Добавить в секцию Storage описание обоих режимов.
    Добавить рекомендацию `.neo-tree-fav.json` в .gitignore при local mode.
  </action>
  <verify>grep -n "storage_mode" README.md</verify>
  <done>README документирует оба режима хранения</done>
</task>

## Success Criteria
- [ ] `storage_mode = "local"` → файл в cwd/.neo-tree-fav.json
- [ ] `storage_mode = "global"` → файл в storage_dir/{name}_{hash}.json (default)
- [ ] README описывает оба режима
