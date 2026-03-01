---
phase: 2
plan: 2
wave: 1
---

# Plan 2.2: Коллизии имён — хинты путей

## Objective

Реализовать обнаружение одноимённых элементов на верхнем уровне и добавление хинтов путей в формате `name [relative/path/]`. Например, если в избранном два файла `aggregate-root.ts`, один станет `aggregate-root.ts [src/core/domain/]`, а другой получит свой путь.

## Context

- `.gsd/SPEC.md` — требование к коллизиям (Goal 3)
- `.gsd/DECISIONS.md` — ADR-007: модификация item.name после create_item()
- `lua/neo-tree-fav/lib/items.lua` — текущий items builder

## Tasks

<task type="auto">
  <name>Detect и resolve коллизии имён</name>
  <files>lua/neo-tree-fav/lib/items.lua</files>
  <action>
    1. После создания всех items из mock_favorites, но ДО сортировки и рендера:
       - Собрать все top-level children root в таблицу по имени (basename)
       - Найти группы с одинаковыми именами (count > 1)

    2. Для каждой группы коллизий:
       - Вычислить `relative_path = utils.split_path(item.path)` — получить родительский каталог
       - Вычислить hint: взять относительный путь от CWD до родителя
       - Модифицировать `item.name = original_name .. " [" .. hint .. "]"`

    3. Добавить helper функцию `resolve_name_collisions(root, cwd)`:
       ```lua
       local function resolve_name_collisions(root, cwd)
         local name_groups = {}
         for _, child in ipairs(root.children) do
           local base = child.name
           name_groups[base] = name_groups[base] or {}
           table.insert(name_groups[base], child)
         end
         for name, group in pairs(name_groups) do
           if #group > 1 then
             for _, item in ipairs(group) do
               local parent = vim.fn.fnamemodify(item.path, ":h")
               local relative = parent:gsub("^" .. vim.pesc(cwd) .. "/", "")
               item.name = name .. " [" .. relative .. "]"
             end
           end
         end
       end
       ```

    4. Добавить дополнительные mock-файлы для тестирования коллизий:
       - Добавить mock с путём, у которого basename совпадает с существующим
       - Например: `my-project/src/modules/users/domain/value-object.ts` — создаст коллизию с `my-project/src/core/domain/value-object.ts`

    5. НЕ менять item.id — он остаётся = path (уникальный)
    6. НЕ менять item.path — только item.name
  </action>
  <verify>
    В Neovim `<leader>F`:
    - `value-object.ts [my-project/src/core/domain]`
    - `value-object.ts [my-project/src/modules/users/domain]`
    - `aggregate-root.ts` (без hint, т.к. уникальный)
  </verify>
  <done>
    - Коллизии обнаруживаются и разрешаются хинтами в []
    - Уникальные имена НЕ получают хинтов
    - item.id и item.path не изменены
  </done>
</task>

<task type="checkpoint:human-verify">
  <name>Визуальная проверка полного дерева</name>
  <files>нет изменений</files>
  <action>
    Пользователь проверяет:
    1. `<leader>F` — полное дерево с моками
    2. Коллизии отображаются с хинтами путей
    3. Папки раскрываются с реальным содержимым
    4. Иконки корректны
    5. Переключение между tabs не ломает другие sources
  </action>
  <verify>
    Пользователь подтверждает визуально.
  </verify>
  <done>
    - Дерево выглядит как ожидается из SPEC
    - Нет визуальных артефактов
    - Все элементы кликабельны (open работает)
  </done>
</task>

## Success Criteria

- [ ] Коллизии имён разрешены хинтами `[relative/path/]`
- [ ] Уникальные имена без хинтов
- [ ] Визуально дерево корректно: иконки, отступы, раскрытие
- [ ] Open (Enter) на файле открывает правильный файл
