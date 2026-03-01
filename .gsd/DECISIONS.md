# DECISIONS.md — Architecture Decision Records

## Format

| ID | Decision | Rationale | Date |
|----|----------|-----------|------|
| ADR-001 | `<leader>F` для открытия Favorites (float) | Не конфликтует с существующими маппингами `<leader>e` (float filesystem) и `<leader>E` (right sidebar) | 2026-03-01 |
| ADR-002 | Данные хранятся в `~/.config/nvim/favorite-projects/` | Плагин независим от проекта, данные живут в конфиге пользователя | 2026-03-01 |
| ADR-003 | Mocks First — сначала визуализация, потом логика | Минимизирует риск неправильного формата данных для neo-tree рендерера | 2026-03-01 |
| ADR-004 | Favorites как вкладка в winbar + отдельный шорткат | Доступен и через переключение табов, и через прямой вызов | 2026-03-01 |
