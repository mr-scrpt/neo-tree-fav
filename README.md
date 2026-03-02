# neo-tree-fav

Custom **Favorites** source for [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) — a personal collection of pinned files and folders with instant access.

## Features

- ⭐ **Favorites tab** in neo-tree (winbar + float)
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
-- Plugin registration (neo-tree-fav.lua)
{
  "your-username/neo-tree-fav",
  dependencies = { "nvim-neo-tree/neo-tree.nvim" },
  config = function()
    require("neo-tree-fav").setup({
      -- All options are optional, defaults shown below
    })
  end,
}

-- Add to your neo-tree config (neotree.lua)
{
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    sources = { "filesystem", "buffers", "git_status", "favorites" },
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

## Configuration

All options with their defaults:

```lua
require("neo-tree-fav").setup({
  -- Display name in neo-tree source selector / winbar
  display_name = " ⭐ Favorites ",

  -- Keymap to open favorites float (nil = don't register)
  keymap = "<leader>F",

  -- ⭐ indicator in filesystem source
  indicator = {
    enabled = true,       -- show ⭐ next to favorited items in filesystem
    icon = " ⭐",         -- icon text (appears after filename)
    highlight = "NeoTreeFavorite",
    highlight_color = "#FFD700",
  },

  -- Key to toggle favorite in filesystem source (nil = don't register)
  filesystem_toggle_key = "F",

  -- Storage mode: "global" or "local"
  -- "global" — all projects in storage_dir (centralized)
  -- "local"  — .neo-tree-fav.json in each project root (cwd)
  storage_mode = "global",

  -- Storage directory for per-project JSON files (only for "global" mode)
  storage_dir = vim.fn.stdpath("config") .. "/neotree-fav",

  -- Log file path
  log_file = vim.fn.stdpath("config") .. "/neotree-fav/neo-tree-fav.log",
})
```

### ⭐ Indicator in Filesystem

To show ⭐ next to favorited items in the filesystem source, add `{ "favorite_indicator" }` to your renderers:

```lua
-- In your neo-tree config:
filesystem = {
  renderers = {
    file = {
      { "indent" },
      { "icon" },
      { "container", content = {
        { "name", zindex = 10 },
        { "favorite_indicator", zindex = 10 },
        { "git_status", zindex = 10, align = "right" },
      }},
    },
    directory = {
      { "indent" },
      { "icon" },
      { "container", content = {
        { "name", zindex = 10 },
        { "favorite_indicator", zindex = 10 },
      }},
    },
  },
}
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

> The `F` mapping in filesystem is registered automatically.

## Storage

### Global mode (default)

Favorites are stored centrally in:

```
~/.config/nvim/neotree-fav/{project_name}_{hash}.json
```

Each project gets its own file based on CWD. The hash ensures uniqueness for same-named projects in different locations.

### Local mode

Favorites are stored in the project root:

```
your-project/.neo-tree-fav.json
```

> **Tip**: Add `.neo-tree-fav.json` to your project's `.gitignore`.

> **Migration**: If you have existing data in `~/.config/nvim/favorite-projects/`, the plugin will automatically use it until you migrate.

## Requirements

- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) v3.x
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- Neovim ≥ 0.9

## License

MIT
