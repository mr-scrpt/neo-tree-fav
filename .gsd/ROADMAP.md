# ROADMAP.md

> **Current Phase**: 3 (Динамическое дерево и Фильтрация)
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

### Phase 3: Динамическое дерево и Фильтрация
**Status**: ⬜ Not Started
**Objective**: Заменить моки на динамическую генерацию узлов. Убедиться, что встроенный поиск/фильтрация neo-tree работают с виртуальными узлами.
**Deliverable**: Поиск по `aggregate` показывает только `domain [src/core] > aggregate-root.ts`.

---

### Phase 4: Персистентность и Управление
**Status**: ⬜ Not Started
**Objective**: Реализовать toggle `F` в filesystem, хранение в JSON per-project, загрузку при старте.
**Deliverable**: Полный цикл: добавить → сохранить → перезапустить → данные на месте.

---

### Phase 5: Финализация и Валидация
**Status**: ⬜ Not Started
**Objective**: Обработка edge-cases (удалённые/перемещённые файлы), FS-watcher, полировка UX.
**Deliverable**: Стабильный, production-ready плагин.
