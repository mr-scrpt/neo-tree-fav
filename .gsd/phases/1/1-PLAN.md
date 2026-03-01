---
phase: 1
plan: 1
wave: 1
---

# Plan 1.1: Структура плагина и Логгер

## Objective

Создать файловую структуру Lua-плагина `neo-tree-fav`, совместимого с lazy.nvim, и модуль логирования. После этого плана плагин должен `require`-аться без ошибок, а логгер — записывать в файл.

## Context

- `.gsd/SPEC.md` — требования к плагину
- `.gsd/RESEARCH.md` — API neo-tree, структура source модуля

## Tasks

<task type="auto">
  <name>Создать структуру Lua-модулей плагина</name>
  <files>
    lua/neo-tree-fav/init.lua
    lua/neo-tree-fav/commands.lua
    lua/neo-tree-fav/components.lua
    lua/neo-tree-fav/lib/items.lua
    lua/neo-tree-fav/lib/storage.lua
    lua/neo-tree-fav/lib/logger.lua
  </files>
  <action>
    1. Создать `lua/neo-tree-fav/init.lua` — точка входа source модуля:
       - Экспортирует `M.name = "favorites"`, `M.display_name = " ⭐ Favorites "`
       - `M.setup(config, global_config)` — пока пустой (подписка на события позже)
       - `M.navigate(state, path, path_to_reveal, callback, async)` — пока вызывает заглушку
       - `M.default_config = {}` — конфиг по умолчанию для source (renderers, components)
       - Использует `require("neo-tree.sources.manager")`, `require("neo-tree.ui.renderer")`
       - НЕ добавлять бизнес-логику — только контракт source

    2. Создать `lua/neo-tree-fav/commands.lua`:
       - Возвращает таблицу с заглушками стандартных команд: `open`, `open_split`, `open_vsplit`, `close_node`, `toggle_node`
       - Переиспользовать `require("neo-tree.sources.common.commands")` для стандартных команд

    3. Создать `lua/neo-tree-fav/components.lua`:
       - Возвращает таблицу компонентов
       - Переиспользовать `require("neo-tree.sources.common.components")` для стандартных (icon, name, indent)

    4. Создать пустые заглушки:
       - `lua/neo-tree-fav/lib/items.lua` — `M.get_favorites(state)` — пока пустая функция
       - `lua/neo-tree-fav/lib/storage.lua` — `M.load()`, `M.save()` — заглушки
  </action>
  <verify>
    В Neovim выполнить:
    :lua print(vim.inspect(require("neo-tree-fav")))
    Должна вернуться таблица с полями: name, display_name, setup, navigate, default_config
  </verify>
  <done>
    - Все 6 Lua-файлов созданы
    - `require("neo-tree-fav")` не выдаёт ошибку
    - Модуль возвращает корректный source-контракт (name, setup, navigate)
  </done>
</task>

<task type="auto">
  <name>Реализовать модуль логирования</name>
  <files>
    lua/neo-tree-fav/lib/logger.lua
  </files>
  <action>
    1. Создать `lua/neo-tree-fav/lib/logger.lua`:
       - Путь лога: `vim.fn.stdpath("config") .. "/neo-tree-favorites.log"`
       - При первом вызове `init()` — очистить файл (truncate)
       - Функции: `logger.info(msg, ...)`, `logger.debug(msg, ...)`, `logger.error(msg, ...)`
       - Формат строки: `[YYYY-MM-DD HH:MM:SS] [LEVEL] message`
       - Использовать `io.open(path, "a")` для записи
       - Ленивая инициализация: файл открывается при первом вызове
       - `logger.init()` — вызывается из `init.lua` при setup()

    2. НЕ использовать neo-tree log (он для внутренних нужд neo-tree, наш лог отдельный)
    3. НЕ использовать vim.notify для дебаг-логов (только для пользовательских уведомлений)
  </action>
  <verify>
    В Neovim выполнить:
    :lua local log = require("neo-tree-fav.lib.logger"); log.init(); log.info("test message")
    Затем проверить содержимое файла:
    :lua print(vim.fn.readfile(vim.fn.stdpath("config") .. "/neo-tree-favorites.log")[1])
    Должна быть строка вида: [2026-03-01 13:00:00] [INFO] test message
  </verify>
  <done>
    - Логгер записывает в файл `~/.config/nvim/neo-tree-favorites.log`
    - Файл очищается при `init()`
    - Формат строк корректный
  </done>
</task>

## Success Criteria

- [ ] `require("neo-tree-fav")` возвращает валидный source-модуль
- [ ] `require("neo-tree-fav.commands")` возвращает таблицу команд
- [ ] `require("neo-tree-fav.components")` возвращает таблицу компонентов
- [ ] Логгер пишет в файл с корректным форматом
- [ ] Файл лога очищается при init()
