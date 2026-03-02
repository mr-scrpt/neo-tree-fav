# ROADMAP.md

> **Current Phase**: 6 (Complete)
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
**Status**: ✅ Complete
**Objective**: Заменить моки на динамическую генерацию из per-project JSON. Toggle `F` в filesystem.
**Deliverable**: storage.lua (get/add/remove/toggle/has), items.lua использует storage.get(), F в filesystem через autocmd, фильтрация пересобирает дерево.

---

### Phase 5: Персистентность и Управление
**Status**: ✅ Complete
**Objective**: Хранение в JSON per-project, загрузка при старте, message-node для пустого.
**Deliverable**: storage.lua с per-project JSON в ~/.config/nvim/favorite-projects/, message-node при пустом списке.

---

### Phase 6: Финализация и Валидация
**Status**: ✅ Complete
**Objective**: Edge-cases (удалённые/перемещённые файлы), FS-watcher, полировка UX.
**Depends on**: Phase 5

**Tasks**:
- [ ] Edge-cases: удалённые/перемещённые файлы
- [ ] FS-watcher интеграция
- [ ] Jump between matches: `<Tab>`/`<S-Tab>` прыгает по файлам, пропуская папки в фильтрованном дереве (renderer.select_nodes API)
- [ ] Полировка UX

**Deliverable**: Стабильный, production-ready плагин.

---

### Phase 7: FS-watcher для автообновления
**Status**: ⬜ Not Started
**Objective**: Автоматическое обновление favorites tree при изменениях в файловой системе (создание/удаление/переименование файлов внутри favorited директорий).
**Depends on**: Phase 6

**Tasks**:
- [ ] TBD (run /plan 7 to create)

**Deliverable**: Favorites автоматически обновляется при изменениях FS без ручного refresh.

---

### Phase 8: Иконка ⭐ для favorited файлов в filesystem
**Status**: ✅ Complete
**Objective**: В стандартном проводнике filesystem отображать иконку ⭐ рядом с файлами/папками которые добавлены в избранное.
**Depends on**: Phase 6

**Tasks**:
- [ ] TBD (run /plan 8 to create)

**Deliverable**: В filesystem source рядом с favorited элементами отображается ⭐.
