---
phase: 4
plan: 2
wave: 2
---

# Plan 4.2: Toggle F в filesystem + auto-refresh

## Objective

Добавить клавишу `F` во вкладке filesystem для toggle добавления/удаления текущего файла/папки
в избранное. При toggle — автоматический refresh вкладки favorites.

## Context

- `.gsd/SPEC.md` — Goal 2 (toggle)
- `lua/neo-tree-fav/lib/storage.lua` — storage module (из Plan 4.1)
- `lua/neo-tree-fav/init.lua` — setup, events
- `lua/neo-tree-fav/commands.lua` — текущие команды

## Tasks

<task type="auto">
  <name>Команда toggle_favorite + маппинг F</name>
  <files>
    lua/neo-tree-fav/commands.lua
    lua/neo-tree-fav/init.lua
  </files>
  <action>
    1. В `commands.lua` добавить:
       ```lua
       M.toggle_favorite = function(state)
         local node = state.tree:get_node()
         if not node or node.type == "message" then return end
         local path = node:get_id()
         local storage = require("neo-tree-fav.lib.storage")
         local added = storage.toggle(path)
         local action = added and "Added to" or "Removed from"
         vim.notify(action .. " favorites: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
         -- Refresh favorites source if it's open
         local manager = require("neo-tree.sources.manager")
         pcall(manager.refresh, "favorites")
       end
       ```

    2. В `init.lua` → `default_config.window.mappings` добавить:
       ```lua
       ["F"] = "toggle_favorite",
       ```

    3. Зарегистрировать `toggle_favorite` как команду для filesystem source:
       В `setup()` добавить регистрацию команды toggle_favorite в filesystem:
       ```lua
       -- Register F mapping in filesystem source
       local neo_tree_config = require("neo-tree").config
       if neo_tree_config.filesystem then
         local fs_mappings = neo_tree_config.filesystem.window.mappings
         if not fs_mappings["F"] then
           fs_mappings["F"] = {
             command = function(state)
               M.commands.toggle_favorite(state)
             end,
             nowait = true,
           }
         end
       end
       ```

    АЛЬТЕРНАТИВА (проще и надёжнее):
    Вместо хака с config, попросить пользователя добавить маппинг в свой конфиг neo-tree:
    ```lua
    filesystem = {
      window = {
        mappings = {
          ["F"] = function(state)
            require("neo-tree-fav.lib.storage").toggle(state.tree:get_node():get_id())
            require("neo-tree.sources.manager").refresh("favorites")
          end,
        },
      },
    }
    ```

    РЕШЕНИЕ: Реализовать оба — программный маппинг в setup() И документация для ручной настройки.
    Программный маппинг через `commands` таблицу filesystem — изучить как neo-tree позволяет
    добавлять кастомные команды к другим sources.
  </action>
  <verify>
    В filesystem tab: навести на файл, нажать `F` → уведомление "Added to favorites".
    `<leader>F` → файл виден в favorites.
    В filesystem: `F` на том же файле → "Removed from favorites".
    `<leader>F` → файл пропал.
  </verify>
  <done>F в filesystem toggles favorite, favorites source обновляется.</done>
</task>

<task type="checkpoint:human-verify">
  <name>Полный цикл: filesystem F → favorites tree</name>
  <action>
    1. Открыть filesystem tab
    2. Навести на файл → `F` → уведомление "Added"
    3. `<leader>F` → файл виден в favorites
    4. filesystem tab → `F` на том же файле → "Removed"
    5. `<leader>F` → файл пропал (или message "Нет избранных")
  </action>
  <done>Пользователь подтвердил полный цикл</done>
</task>

## Success Criteria

- [ ] `F` в filesystem добавляет/удаляет из избранного
- [ ] Уведомление о toggle
- [ ] Favorites source обновляется при toggle
- [ ] Полный цикл работает
