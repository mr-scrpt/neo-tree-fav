---
phase: 6
plan: 1
wave: 1
---

# Plan 6.1: Edge-cases и валидация путей

## Objective
Обработать удалённые/перемещённые файлы в избранном и валидировать F key в filesystem.

## Context
- .gsd/SPEC.md
- lua/neo-tree-fav/lib/items.lua
- lua/neo-tree-fav/lib/storage.lua
- lua/neo-tree-fav/init.lua

## Tasks

<task type="auto">
  <name>Отображение недоступных путей</name>
  <files>lua/neo-tree-fav/lib/items.lua</files>
  <action>
    В get_favorites, если `uv.fs_stat(path)` возвращает nil (файл удалён/перемещён):
    - НЕ пропускать (сейчас пропускается через logger.warn)
    - Создать узел с type="file", name со стилем `[missing] filename`
    - Добавить `extra.missing = true` для возможной стилизации
    - Такой узел НЕ сканируется рекурсивно (нет FS)
  </action>
  <verify>
    1. Добавить файл в избранное
    2. Удалить его из FS
    3. Открыть favorites — файл должен отображаться как [missing]
  </verify>
  <done>Удалённые файлы видны в favorites с меткой [missing], не крашат плагин</done>
</task>

<task type="auto">
  <name>Команда очистки недоступных путей</name>
  <files>lua/neo-tree-fav/commands.lua, lua/neo-tree-fav/lib/storage.lua</files>
  <action>
    Добавить команду `clean_missing` в commands.lua:
    - Вызывает storage.clean_missing() — удаляет все пути где fs_stat=nil
    - Обновляет favorites source
    - vim.notify с количеством удалённых

    В storage.lua добавить:
    - `M.clean_missing()` — фильтрует список, оставляя только существующие пути
    - Сохраняет обновлённый JSON

    Замаппить на `X` в favorites window (init.lua default_config.window.mappings).
  </action>
  <verify>
    1. Добавить файлы, удалить часть из FS
    2. Открыть favorites — видны [missing]
    3. Нажать X — missing удалены, уведомление
  </verify>
  <done>X удаляет все missing пути, JSON обновлён, уведомление показано</done>
</task>

<task type="checkpoint:human-verify">
  <name>Проверка F key в filesystem</name>
  <files>lua/neo-tree-fav/init.lua</files>
  <action>
    Проверить что F key в filesystem source работает корректно через autocmd.
    Если не работает — исследовать альтернативные подходы:
    1. Проверить что autocmd FileType neo-tree срабатывает
    2. Проверить что buf var neo_tree_source == "filesystem" установлен
    3. При необходимости — задокументировать ручной маппинг в README
  </action>
  <verify>
    Filesystem tab → F на файле → "Added to favorites" уведомление
  </verify>
  <done>F key работает в filesystem либо задокументирован workaround</done>
</task>

## Success Criteria
- [ ] Удалённые файлы отображаются как [missing] в favorites
- [ ] Команда X очищает missing пути
- [ ] F key в filesystem добавляет/убирает из избранного
