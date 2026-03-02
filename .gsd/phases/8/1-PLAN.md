---
phase: 8
plan: 1
wave: 1
---

# Plan 8.1: Иконка ⭐ для favorited файлов в filesystem

## Objective
В стандартном filesystem source отображать ⭐ рядом с файлами/папками, которые добавлены в избранное.

## Context
- lua/neo-tree-fav/init.lua (setup, autocmd)
- lua/neo-tree-fav/lib/storage.lua (storage.has)
- neo-tree setup/init.lua:537 — `source_default_config.components = require(mod_root .. ".components")`
- neo-tree ui/renderer.lua:354 — `state.components[component[1]]`
- neo-tree defaults.lua:303-350 — renderers.file/directory component lists

## Research Summary

Как neo-tree рендерит деревья:
1. Каждый source имеет `components` таблицу (функции рендеринга)
2. В config `renderers.file` / `renderers.directory` — массив компонентов в порядке отображения
3. Renderer вызывает `state.components[component_name](config, node, state)` для каждого
4. `state.components` загружается из `require("neo-tree.sources.<source>.components")`

Стратегия:
- Inject `favorite_indicator` функцию в filesystem components table
- Добавить `{ "favorite_indicator" }` в filesystem renderers через user config injection
- `favorite_indicator` вызывает `storage.has(node.path)` → возвращает ⭐ или nil

## Tasks

<task type="auto">
  <name>Создать favorite_indicator компонент и инжектировать в filesystem</name>
  <files>lua/neo-tree-fav/init.lua</files>
  <action>
    В `M.setup()` после autocmd-блока добавить инжекцию компонента:

    1. Получить filesystem components:
       `local fs_components = require("neo-tree.sources.filesystem.components")`

    2. Добавить функцию `favorite_indicator`:
       ```lua
       fs_components.favorite_indicator = function(config, node, state)
         local storage = require("neo-tree-fav.lib.storage")
         if storage.has(node.path or node:get_id()) then
           return { text = "⭐ ", highlight = "NeoTreeFavorite" }
         end
       end
       ```

    3. Определить highlight group:
       `vim.api.nvim_set_hl(0, "NeoTreeFavorite", { fg = "#FFD700", default = true })`

    НЕ модифицировать renderers config автоматически —
    пользователь добавляет `{ "favorite_indicator" }` в свой config сам.
    Это стандартный подход neo-tree (компоненты opt-in).
  </action>
  <verify>
    1. Открыть filesystem
    2. Файлы добавленные в favourite должны иметь ⭐
  </verify>
  <done>⭐ отображается рядом с favorited файлами в filesystem</done>
</task>

<task type="auto">
  <name>Документировать настройку в README</name>
  <files>README.md</files>
  <action>
    Добавить секцию "⭐ Indicator in Filesystem" с примером
    neo-tree config для добавления `{ "favorite_indicator" }`:

    ```lua
    filesystem = {
      renderers = {
        file = {
          { "indent" },
          { "icon" },
          { "favorite_indicator" }, -- ← добавить
          { "container", content = { ... } },
        },
        directory = {
          { "indent" },
          { "icon" },
          { "favorite_indicator" }, -- ← добавить
          { "container", content = { ... } },
        },
      },
    }
    ```
  </action>
  <verify>cat README.md — содержит секцию с примером</verify>
  <done>README содержит инструкцию по добавлению ⭐ indicator</done>
</task>

## Success Criteria
- [ ] `favorite_indicator` компонент инжектирован в filesystem components
- [ ] ⭐ отображается рядом с favorited файлами
- [ ] README содержит инструкцию по настройке
