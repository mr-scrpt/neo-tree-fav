-- neo-tree-fav: Centralized configuration
--
-- All configurable options with defaults.
-- User overrides via require("neo-tree-fav").setup(opts).

local M = {}

---@class NeoTreeFavConfig
M.defaults = {
  -- Display name in neo-tree source selector / winbar
  display_name = " ⭐ Favorites ",

  -- Keymap to open favorites float (nil = don't register)
  keymap = "<leader>F",

  -- ⭐ indicator in filesystem source
  indicator = {
    enabled = true,
    icon = " ⭐",
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
}

---@type NeoTreeFavConfig
M.options = vim.deepcopy(M.defaults)

--- Apply user overrides to config.
---@param opts? table User options to merge with defaults
M.setup = function(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
