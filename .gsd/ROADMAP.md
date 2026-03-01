# ROADMAP.md

> **Current Phase**: 4 (Динамическое дерево и Storage)
> **Milestone**: v1.0

## Must-Haves (from SPEC)

- [ ] Source `favorites` зарегистрирован в neo-tree и доступен через winbar
- [ ] `<leader>F` открывает favorites в float
- [ ] Toggle добавления/удаления через `F` в filesystem
- [ ] Плоский верхний уровень с разрешением коллизий имён
- [ ] Рекурсивное раскрытие избранных папок (реальная FS)
- [ ] Персистентность per-project в JSON
- [ ] Совместимость с фильтрацией/поиском neo-tree

## Phases

### Phase 0: Discovery — Анализ Neo-tree Source API
**Status**: ✅ Complete
**Objective**: Изучить internal API neo-tree для создания кастомных source.
**Deliverable**: `.gsd/RESEARCH.md` с описанием API, формата узлов, контрактов.

---

### Phase 1: Инфраструктура и Логирование
**Status**: ✅ Complete
**Objective**: Создать структуру плагина, модуль логгера, регистрация source.
**Deliverable**: 6 Lua-файлов, логгер, source зарегистрирован, float + winbar работают.

---

### Phase 2: Ядро на моках (Mocks First)
**Status**: ✅ Complete
**Objective**: Реализовать source `favorites` со статическим списком путей (на основе тестовой структуры). Добиться корректной отрисовки в neo-tree с коллизиями имён.
**Deliverable**: `<leader>F` отображает виртуальное дерево из моков. Папки раскрываются, иконки отображаются.

---

### Phase 3: Фильтрация и поиск
**Status**: ✅ Complete
**Objective**: Добавить fuzzy_finder, filter, fuzzy_sorter в favorites source. Тестируем на моках.
**Deliverable**: Маппинги `/`, `f`, `#` работают, фильтрация в реальном времени.

---

### Phase 3.5: Рефакторинг — анализ реиспользования neo-tree internals
**Status**: ✅ Complete
**Objective**: Детальный анализ — можно ли переиспользовать filter/commands из neo-tree напрямую. Вердикт: текущий подход оптимален.
**Deliverable**: Архитектурная документация, cleanup.

---

### Phase 4: Динамическое дерево и Storage
**Status**: ⬜ Not Started
**Objective**: Заменить моки на динамическую генерацию из per-project JSON. Toggle `F` в filesystem.
**Deliverable**: Полный цикл: `F` добавляет → `<leader>F` показывает.

---

### Phase 5: Персистентность и Управление
**Status**: ⬜ Not Started
**Objective**: Хранение в JSON per-project, загрузка при старте, message-node для пустого.
**Deliverable**: Данные сохраняются и восстанавливаются между сессиями.

---

### Phase 6: Финализация и Валидация
**Status**: ⬜ Not Started
**Objective**: Edge-cases (удалённые/перемещённые файлы), FS-watcher, полировка UX.
**Deliverable**: Стабильный, production-ready плагин.
