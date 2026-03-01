# Phase 3.5 Research: Реиспользование neo-tree internals

## Вопрос

Можно ли заменить наши `lib/filter.lua` (230 строк) и `commands.lua` (44 строки) на
переиспользование модулей neo-tree напрямую? Какие варианты: адаптер, wrapper, прямой вызов?

## Анализ текущих модулей neo-tree

### 1. `common/filters/init.lua` (354 строки)

**Что делает**: Generic фильтр — clone tree, remove non-matching nodes, redraw.

**Может ли использоваться напрямую**: ЧАСТИЧНО.
- ✅ `show_filter()` — UI, on_change, clone+filter логика — работает с любым source
- ✅ `setup_hooks()`, `setup_mappings()` — переиспользуемый setup клавиш
- ❌ `reset_filter()` (internal) — вызывает `filter_external.cancel()` (Line 27) и использует
  `manager.navigate(state)` для reset, но НЕ открывает файлы на Enter
- ❌ `setup_mappings()` читает `config.filesystem.window.fuzzy_finder_mappings` (Line 343) —
  хардкод на filesystem

**Проблемы на Enter**: `reset_filter(state, true, true)` только навигирует, а filesystem:
- **file** → `utils.open_file(state, path)` — ОТКРЫВАЕТ файл
- **dir** → navigate + focus_node
- **float** → не делает navigate после open_file

### 2. `filesystem/lib/filter.lua` (242 строки)

**Что делает**: Filesystem-specific фильтр.

**Может ли использоваться напрямую**: НЕТ.
- Импортирует `require("neo-tree.sources.filesystem")` (Line 4) — circular dependency
- Вызывает `fs._navigate_internal()` на каждый keystroke — filesystem-specific
- Вызывает `fs.reset_search()` — filesystem-specific

### 3. `common/commands.lua`

**Что делает**: Общие команды (open, toggle_node, close_node, etc.).

**Может ли использоваться**: ✅ ДА — уже используем через `cc._add_common_commands(M)`.
**Не содержит**: filter/fuzzy_finder/clear_filter (они source-specific).

### 4. `filesystem/commands.lua`

**Содержит**: `fuzzy_finder`, `filter_on_submit`, `fuzzy_sorter`, `clear_filter`.
**Может ли использоваться напрямую**: НЕТ — вызывают `filesystem/lib/filter.lua`.

## Варианты

### A. Wrapper над common/filters (минимальный код)

```lua
-- commands.lua
M.fuzzy_finder = function(state)
  common_filter.show_filter(state, true, false)
end
```

**Проблемы**:
- ❌ Enter не открывает файл (только навигирует)
- ❌ `reset_filter` вызывает `filter_external.cancel()` — ненужный side effect
- ❌ `setup_mappings` хардкодит `config.filesystem`
- Мы пробовали этот вариант → не работает корректно

### B. Наш lib/filter.lua (текущий, 230 строк)

Скопирован паттерн filesystem + clone-filter из common.

**Плюсы**:
- ✅ Работает корректно
- ✅ Enter открывает файл (как filesystem)
- ✅ Контролируем поведение полностью

**Минусы**:
- Дублирование ~100 строк из common/filters (show_filtered_tree, UI setup)
- При обновлении neo-tree — наш код может отстать

### C. Adapter: common/filters + override reset (оптимальный)

Переиспользовать из common/filters:
- `show_filtered_tree` → клонирование + fzy filtering (основная логика, 40 строк)
- UI setup (popup_options, Input creation)
- `setup_hooks`, `setup_mappings`

Написать своё:
- `reset_search` (наш, 30 строк) — файл→open_file, dir→navigate
- `on_submit` handler — вызывает наш reset_search
- `close` handler — vim.defer_fn pattern

**Итого**: ~120 строк вместо 230, переиспользование ~60% из common/filters.

## Решение

**Вариант C**: Нельзя использовать `common/filters.show_filter` as-is из-за `reset_filter`
и `setup_mappings` hardcoded на filesystem. Но можно:

1. Импортировать `fzy` модуль из common/filters для scoring (уже делаем)
2. Переиспользовать `setup_hooks` и `setup_mappings` (уже делаем)
3. Единственная реально дублируемая логика — `show_filtered_tree` (40 строк) и UI setup (30 строк)
4. Наш `reset_search` (30 строк) — ОБЯЗАТЕЛЬНО свой, т.к. filesystem-specific

**Вывод**: Текущий `lib/filter.lua` уже оптимален — он переиспользует `fzy`, `setup_hooks`,
`setup_mappings` из common, и добавляет только то, что нельзя взять (reset_search, show_filtered_tree).
Дальнейшее сокращение невозможно без форка neo-tree.

**Рекомендация**: Оставить как есть. Добавить комментарии с ссылками на оригинальные модули
для упрощения сопровождения при обновлениях neo-tree.
