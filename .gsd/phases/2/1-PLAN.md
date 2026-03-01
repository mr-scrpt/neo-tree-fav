---
phase: 2
plan: 1
wave: 1
---

# Plan 2.1: Мок-данные и рендеринг виртуального дерева

## Objective

Заполнить `items.lua` статическим списком путей из тестового проекта `my-project/` и добиться корректной отрисовки дерева в neo-tree с иконками, отступами и раскрытием папок. После этого `<leader>F` показывает реальные файлы из mock-списка.

## Context

- `.gsd/RESEARCH.md` — паттерн из `git_status/lib/items.lua`
- `lua/neo-tree-fav/lib/items.lua` — текущая заглушка
- `lua/neo-tree-fav/init.lua` — source module
- `my-project/` — тестовая структура с файлами

## Tasks

<task type="auto">
  <name>Реализовать мок-данные в items.lua</name>
  <files>lua/neo-tree-fav/lib/items.lua</files>
  <action>
    1. Добавить статический список mock-путей, имитирующий избранные файлы и папки:
       ```lua
       local mock_favorites = {
         -- Файлы
         { path = "my-project/src/core/domain/aggregate-root.ts", type = "file" },
         { path = "my-project/src/core/domain/value-object.ts", type = "file" },
         { path = "my-project/src/modules/users/domain/entities/user.entity.ts", type = "file" },
         { path = "my-project/infrastructure/database/prisma/schema.prisma", type = "file" },
         -- Папки
         { path = "my-project/infrastructure/database/migrations", type = "directory" },
       }
       ```

    2. В `get_favorites()` заменить TODO на цикл по mock_favorites:
       - Для каждого элемента вычислить абсолютный путь через `vim.fn.getcwd() .. "/" .. item.path`
       - Вызвать `file_items.create_item(context, abs_path, item.type)`
       - Для папок: установить `loaded = false` (чтобы иконка показывала закрытую папку)
       - Для файлов: просто создать item

    3. Сохранить `state.default_expanded_nodes = { root.path }` — раскрыта только root

    4. НЕ обрабатывать коллизии в этой задаче — это задача 2.2
    5. НЕ реализовывать загрузку из папки — моки захардкожены
  </action>
  <verify>
    В Neovim выполнить `:Neotree float favorites`. Должно отобразиться дерево:
    - FAVORITES (root)
      - aggregate-root.ts
      - value-object.ts
      - user.entity.ts
      - schema.prisma
      - migrations (папка, закрытая)
    С иконками для .ts, .prisma файлов и папок.
  </verify>
  <done>
    - `<leader>F` показывает 5 элементов из mock_favorites
    - Файлы имеют корректные иконки (TypeScript, Prisma)
    - Папка migrations отображается с иконкой папки
    - Нет ошибок в `:messages`
  </done>
</task>

<task type="auto">
  <name>Раскрытие папок через uv.fs_scandir</name>
  <files>
    lua/neo-tree-fav/lib/items.lua
    lua/neo-tree-fav/init.lua
  </files>
  <action>
    1. В `items.lua` добавить функцию `M.expand_directory(state, dir_path)`:
       - Использовать `vim.uv.fs_scandir(dir_path)` для чтения содержимого папки
       - Для каждого файла/папки вызвать `file_items.create_item(context, child_path, child_type)`
       - Установить `folder.loaded = true` для раскрытой папки
       - Вызвать `renderer.show_nodes({ root }, state)` для перерисовки

    2. В `init.lua` модифицировать `M.navigate()`:
       - Если `path_to_reveal` указан и это подпапка текущего состояния — перестроить дерево

    3. Основной подход — при рендеринге дерева проверять `state.explicitly_opened_directories`:
       - Для каждой папки из favorites, если она в списке раскрытых — сканировать содержимое через `uv.fs_scandir`
       - Рекурсивно для вложенных папок

    4. НЕ делать асинхронное сканирование (sync достаточен для наших целей)
    5. НЕ использовать fs_scan из filesystem source (ADR-008)
  </action>
  <verify>
    В Neovim:
    1. `<leader>F`
    2. Навести курсор на папку `migrations`
    3. Нажать `<space>` или `<cr>` для раскрытия
    4. Должны появиться: `20260301-init.ts`, `20260302-seed.ts`
  </verify>
  <done>
    - Папка migrations раскрывается и показывает 2 файла
    - Повторное нажатие складывает папку
    - Вложенные папки тоже раскрываются рекурсивно
  </done>
</task>

## Success Criteria

- [ ] `<leader>F` показывает дерево с 5 mock-элементами
- [ ] Файлы имеют корректные иконки (по расширению)
- [ ] Папка раскрывается и показывает реальное содержимое FS
- [ ] Вложенные папки тоже раскрываются
- [ ] Нет ошибок в `:messages`
