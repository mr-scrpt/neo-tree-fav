# neo-tree-fav

Custom **Favorites** source for [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) — a personal collection of pinned files and folders with instant access.

## Features

- ⭐ **Favorites tab** in neo-tree (winbar + float via `<leader>F`)
- 🔄 **Toggle** favorites with `F` from filesystem source
- 📂 **Recursive directory expansion** — favorited folders show real FS contents
- 🔍 **Fuzzy search** with `Tab`/`S-Tab` to jump between file matches
- 🏷️ **Name collision resolution** — `domain [src/core]` vs `domain [src/modules]`
- 💾 **Per-project persistence** in JSON
- ⚠️ **Missing file detection** — deleted files shown as `[missing]`
- ⭐ **Star indicator** in filesystem — favorited items show ⭐ icon

## Installation

### lazy.nvim

```lua
{
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    -- Add as a local plugin during development:
    { dir = "/path/to/neo-tree-fav" },
    -- Or from GitHub:
    -- "your-username/neo-tree-fav",
  },
  opts = {
    sources = {
      "filesystem",
      "buffers",
      "git_status",
      "favorites",  -- ← add this
    },
    source_selector = {
      sources = {
        { source = "filesystem" },
        { source = "buffers" },
        { source = "git_status" },
        { source = "favorites", display_name = " ⭐ Favorites " },
      },
    },
  },
}
```

### Keymap

```lua
vim.keymap.set("n", "<leader>F", function()
  vim.cmd("Neotree source=favorites position=float toggle")
end, { desc = "Toggle Favorites (float)" })
```

## Mappings

### In Favorites tab

| Key | Action |
|-----|--------|
| `/` | Fuzzy finder |
| `f` | Filter (submit on Enter) |
| `#` | Fuzzy sorter |
| `F` | Remove from favorites |
| `X` | Clean all missing (deleted) paths |
| `<C-x>` | Clear filter |

### In Fuzzy Finder

| Key | Action |
|-----|--------|
| `↑` / `<C-p>` | Previous item |
| `↓` / `<C-n>` | Next item |
| `<Tab>` | Jump to next **file** (skip folders) |
| `<S-Tab>` | Jump to prev **file** (skip folders) |
| `<Enter>` | Open file / focus directory |
| `<Esc>` | Close filter |
| `<S-Enter>` | Close, keep filter |

### In Filesystem tab

| Key | Action |
|-----|--------|
| `F` | Toggle favorite (add/remove) |

> The `F` mapping in filesystem is registered automatically via autocmd.

## ⭐ Indicator in Filesystem

To show ⭐ next to favorited items in the filesystem source, add `{ "favorite_indicator" }` to your renderers:

```lua
-- In your neo-tree config:
filesystem = {
  renderers = {
    file = {
      { "indent" },
      { "icon" },
      { "favorite_indicator" }, -- ⭐
      { "container", content = {
        { "name", zindex = 10 },
        { "git_status", zindex = 10, align = "right" },
      }},
    },
    directory = {
      { "indent" },
      { "icon" },
      { "favorite_indicator" }, -- ⭐
      { "container", content = {
        { "name", zindex = 10 },
      }},
    },
  },
}
```

The highlight group `NeoTreeFavorite` (gold `#FFD700`) is set automatically.

## Storage

Favorites are stored per-project in:

```
~/.config/nvim/favorite-projects/{project_name}_{hash}.json
```

Each project gets its own file based on CWD. The hash ensures uniqueness for same-named projects in different locations.

## Requirements

- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) v3.x
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- Neovim ≥ 0.9

## License

MIT
