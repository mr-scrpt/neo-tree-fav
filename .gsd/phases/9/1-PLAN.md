---
phase: 9
plan: 1
wave: 1
---

# Plan 9.1: Конфигурируемые опции через setup(opts)

## Objective
Вынести все захардкоженные значения в конфигурируемые параметры, чтобы пользователь
мог перезадать их через `require("neo-tree-fav").setup(opts)`.

## Context
- lua/neo-tree-fav/init.lua (setup, default_config, keymaps)
- lua/neo-tree-fav/lib/storage.lua (storage_dir hardcoded)
- lua/neo-tree-fav/lib/logger.lua (log_path hardcoded)

## Hardcoded Values (audit)

| Файл | Значение | Опция |
|------|----------|-------|
| init.lua:14 | `" ⭐ Favorites "` | `display_name` |
| init.lua:165 | `#FFD700` | `indicator.highlight_color` |
| init.lua:174 | `" ⭐"` | `indicator.icon` |
| init.lua:143 | `"F"` (filesystem toggle) | `filesystem_toggle_key` |
| init.lua:92-97 | window.mappings | уже конфигурируемо через neo-tree |
| storage.lua:19 | `favorite-projects` | `storage_dir` |
| logger.lua:16 | `neo-tree-favorites.log` | `log_file` |

## Tasks

<task type="auto">
  <name>Создать config module и defaults</name>
  <files>lua/neo-tree-fav/lib/config.lua</files>
  <action>
    Создать `config.lua` с дефолтами и merge-функцией:

    ```lua
    local M = {}
    M.defaults = {
      display_name = " ⭐ Favorites ",
      indicator = {
        enabled = true,
        icon = " ⭐",
        highlight = "NeoTreeFavorite",
        highlight_color = "#FFD700",
      },
      filesystem_toggle_key = "F",
      storage_dir = vim.fn.stdpath("data") .. "/neo-tree-favorites",
      log_file = vim.fn.stdpath("data") .. "/neo-tree-favorites.log",
    }
    M.options = vim.deepcopy(M.defaults)
    M.setup = function(opts)
      M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
    end
    ```

    ВАЖНО: storage_dir по дефолту изменить на stdpath("data") вместо
    stdpath("config") — это стандартная практика для данных плагинов.
    Нужно предусмотреть миграцию: если старая папка существует, использовать её.
  </action>
  <verify>grep -n "M.defaults" lua/neo-tree-fav/lib/config.lua</verify>
  <done>config.lua создан с полными defaults и setup()</done>
</task>

<task type="auto">
  <name>Подключить config ко всем модулям</name>
  <files>
    lua/neo-tree-fav/init.lua
    lua/neo-tree-fav/lib/storage.lua
    lua/neo-tree-fav/lib/logger.lua
  </files>
  <action>
    1. init.lua:
       - M.setup() вызывает config.setup(opts) первым
       - display_name берётся из config.options.display_name
       - indicator icon/highlight из config.options.indicator.*
       - filesystem_toggle_key из config.options.filesystem_toggle_key
       - Если config.options.indicator.enabled == false → не инжектить компонент

    2. storage.lua:
       - get_storage_path() использует config.options.storage_dir
       - Добавить миграцию: если stdpath("config")/favorite-projects существует
         и новая папка пуста → скопировать/использовать старую

    3. logger.lua:
       - log_path из config.options.log_file
  </action>
  <verify>
    grep -rn "config.options" lua/neo-tree-fav/
  </verify>
  <done>Все модули используют config.options вместо хардкода</done>
</task>

## Success Criteria
- [ ] config.lua с дефолтами и setup()
- [ ] Все хардкоды заменены на config.options.*
- [ ] setup({}) без аргументов работает как раньше (backward compatible)
