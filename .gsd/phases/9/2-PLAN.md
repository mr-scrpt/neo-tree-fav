---
phase: 9
plan: 2
wave: 2
---

# Plan 9.2: Подготовка пакета для GitHub

## Objective
Структурировать проект для публикации на GitHub как lazy.nvim-compatible плагин.

## Context
- Root directory structure
- README.md
- .gitignore (отсутствует)

## Tasks

<task type="auto">
  <name>Создать .gitignore и LICENSE</name>
  <files>.gitignore, LICENSE</files>
  <action>
    1. .gitignore:
       ```
       # Dev artifacts
       my-project/
       logs/
       .gsd/
       scripts/
       adapters/
       docs/
       reference/
       GSD-STYLE.md
       PROJECT_RULES.md
       model_capabilities.yaml
       .agent/
       .gemini/
       ```

    2. LICENSE — MIT license с именем автора

    НЕ удалять файлы — только игнорировать.
    Пользователь может удалить dev-файлы сам перед push.
  </action>
  <verify>cat .gitignore && cat LICENSE</verify>
  <done>.gitignore и LICENSE созданы</done>
</task>

<task type="auto">
  <name>Обновить README для публичного использования</name>
  <files>README.md</files>
  <action>
    Обновить README:
    1. Installation — заменить `dir = "/path/to/..."` на GitHub URL
    2. Добавить секцию Configuration с примером setup(opts)
    3. Показать все доступные опции с дефолтами
    4. Убрать упоминания dev-path
  </action>
  <verify>cat README.md | head -60</verify>
  <done>README готов для публичного репо</done>
</task>

## Success Criteria
- [ ] .gitignore отсекает dev-артефакты
- [ ] LICENSE MIT
- [ ] README с GitHub-ориентированной установкой и документацией конфига
