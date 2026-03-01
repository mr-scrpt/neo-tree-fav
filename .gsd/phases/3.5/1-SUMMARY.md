# Phase 3.5 Summary: Audit neo-tree internals reuse

## Verdict: Current approach is optimal

### What's reused from neo-tree (no custom code needed):
- `fzy` — fuzzy scoring/matching
- `setup_hooks` — BufLeave/BufDelete auto-close
- `setup_mappings` — ↑↓ Esc keybindings
- `_add_common_commands` — open, toggle, copy, paste, etc.
- `nui.input` + `popups` — UI primitives

### What's custom and WHY:
- `show_filtered_tree` (40 lines) — common/filters hardcodes `filter_external.cancel()` and `config.filesystem`
- `reset_search` (30 lines) — common/filters only navigates, filesystem opens files on Enter
- `on_change` empty handler — matches filesystem/lib/filter.lua:144-154

### Changes made:
- `filter.lua`: Added ARCHITECTURE doc comment with references
- `commands.lua`: Removed unused `redraw`, added architecture docs
