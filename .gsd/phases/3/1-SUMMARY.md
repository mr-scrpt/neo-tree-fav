# Phase 3 Summary: Фильтрация и поиск

## Delivered
- **lib/filter.lua** — Filter module modeled on `filesystem/lib/filter.lua`
  - `on_change`: clone+filter tree approach (from `common/filters`), nil-safe `node.extra`
  - `on_submit` (Enter): filesystem pattern — file → `utils.open_file`, dir → navigate+focus
  - `close` (Esc): `vim.defer_fn(100)` to avoid double-reset
  - Uses `common_filter.setup_hooks/setup_mappings` for keyboard navigation

- **commands.lua** — `fuzzy_finder`, `filter_on_submit`, `fuzzy_sorter`, `clear_filter`

- **init.lua** — Mappings: `/`, `f`, `#`, `<C-x>`

- **items.lua** — Added `extra = {}` on all items for filter compatibility

## Key Findings
- `common/filters` is a generic filter that clones tree and removes non-matching nodes
- Filesystem uses its OWN `filter.lua` + `fs.reset_search` (NOT `common/filters`)
- Filesystem's `reset_search` opens files directly (`utils.open_file`) — this is why Enter opens files
- `common/filters`' `reset_filter` has hardcoded filesystem dependencies (`filter_external.cancel()`)

## Open Question (→ Next Phase)
Can we reduce our custom code by reusing neo-tree internals more directly?
Current custom modules: `lib/filter.lua` (230 lines), `commands.lua` (44 lines).
Need analysis of adapter/wrapper approach vs current copy-adapt approach.

## Verification
- ✅ `/` opens fuzzy finder, filters in real-time
- ✅ Enter on file → opens in editor
- ✅ Enter on directory → focuses in tree
- ✅ Esc → closes filter, restores tree
- ✅ `<C-x>` → clears filter
- ✅ No duplicate nodes
