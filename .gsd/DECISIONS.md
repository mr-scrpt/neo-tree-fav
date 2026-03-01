# DECISIONS.md — Architecture Decision Records

## Format

| ID | Decision | Rationale | Date |
|----|----------|-----------|------|
| ADR-001 | `<leader>F` для открытия Favorites (float) | Не конфликтует с существующими маппингами `<leader>e` (float filesystem) и `<leader>E` (right sidebar) | 2026-03-01 |
| ADR-002 | Данные хранятся в `~/.config/nvim/favorite-projects/` | Плагин независим от проекта, данные живут в конфиге пользователя | 2026-03-01 |
| ADR-003 | Mocks First — сначала визуализация, потом логика | Минимизирует риск неправильного формата данных для neo-tree рендерера | 2026-03-01 |
| ADR-004 | Favorites как вкладка в winbar + отдельный шорткат | Доступен и через переключение табов, и через прямой вызов | 2026-03-01 |
| ADR-005 | Регистрация через `sources` в конфиге neo-tree (external namespace) | Neo-tree нативно поддерживает внешние модули: `pcall(require, source_name)`. Не нужен `package.preload`. | 2026-03-01 |
| ADR-006 | Использование `file_items.create_item()` для всех узлов | Обеспечивает совместимость с фильтрацией, поиском, сортировкой и всеми стандартными компонентами neo-tree | 2026-03-01 |
| ADR-007 | Коллизии имён: модификация `item.name` после `create_item()` | Формат: `name [relative/path/]`. Простая реализация, совместимая с fuzzy finder. `item.id = path` остаётся уникальным | 2026-03-01 |
| ADR-008 | Раскрытие папок: `uv.fs_scandir()` + `create_item()` | Избегаем зависимости от `fs_scan` (привязан к filesystem source). Прямой вызов libuv проще и достаточен для наших целей | 2026-03-01 |
