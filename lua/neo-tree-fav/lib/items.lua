-- neo-tree-fav: Items builder for the favorites tree
-- Follows the EXACT pattern from buffers/lib/items.lua and git_status/lib/items.lua:
-- create_context → create_item per path → advanced_sort → renderer.show_nodes

local uv = vim.uv or vim.loop
local renderer = require("neo-tree.ui.renderer")
local file_items = require("neo-tree.sources.common.file-items")
local logger = require("neo-tree-fav.lib.logger")

local M = {}

-- ── Mock Data ──────────────────────────────────────────────────────────────

--- Get the plugin's installation directory.
---@return string
local function get_plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h:h")
end

local function get_mock_favorites()
  local root = get_plugin_root()
  return {
    root .. "/my-project/src/core/domain/aggregate-root.ts",
    root .. "/my-project/src/core/domain/value-object.ts",
    root .. "/my-project/src/modules/users/domain/entities/user.entity.ts",
    root .. "/my-project/infrastructure/database/prisma/schema.prisma",
    root .. "/my-project/infrastructure/database/migrations",
  }
end

-- ── Directory Scanner ──────────────────────────────────────────────────────

--- Recursively scan a real FS directory and add all children via create_item.
--- create_item's set_parents will auto-parent them under the correct folder.
---@param context table file_items context
---@param dir_path string Absolute path to directory
local function scan_directory_recursive(context, dir_path)
  local handle = uv.fs_scandir(dir_path)
  if not handle then
    logger.warn("scan_directory: cannot read %s", dir_path)
    return
  end

  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end

    local child_path = dir_path .. "/" .. name
    if not type then
      local stat = uv.fs_stat(child_path)
      type = stat and stat.type == "directory" and "directory" or "file"
    end

    local success, item = pcall(file_items.create_item, context, child_path, type)
    if success then
      if type == "directory" then
        item.loaded = true
        scan_directory_recursive(context, child_path)
      end
    else
      logger.error("scan_directory: %s: %s", child_path, tostring(item))
    end
  end
end

-- ── Main Entry Point ───────────────────────────────────────────────────────

--- Build and render the favorites tree.
--- Uses the standard neo-tree pattern:
--- 1. create_context
--- 2. create_item for root
--- 3. create_item for each favorite path (set_parents auto-builds hierarchy)
--- 4. For favorite directories: scan real FS contents recursively
--- 5. advanced_sort + show_nodes
---
--- All intermediate folders between root and favorites are auto-created
--- by create_item's set_parents, and auto-expanded via default_expanded_nodes.
--- Standard neo-tree mechanisms handle toggle, search, filter.
---@param state neotree.StateWithTree
M.get_favorites = function(state)
  if state.loading then return end
  state.loading = true
  logger.debug("get_favorites: building tree for path=%s", state.path)

  local context = file_items.create_context()
  context.state = state

  -- Root folder
  local root = file_items.create_item(context, state.path, "directory")
  root.name = "Favorites"
  root.loaded = true
  root.search_pattern = state.search_pattern
  context.folders[root.path] = root

  -- Add each favorite path via standard create_item.
  -- set_parents auto-creates all intermediate directories in the hierarchy.
  local favorites = get_mock_favorites()
  for _, path in ipairs(favorites) do
    local stat = uv.fs_stat(path)
    if stat then
      local ftype = stat.type == "directory" and "directory" or "file"
      local success, item = pcall(file_items.create_item, context, path, ftype)
      if success then
        if ftype == "directory" then
          item.loaded = true
          scan_directory_recursive(context, path)
        end
      else
        logger.error("get_favorites: %s: %s", path, tostring(item))
      end
    else
      logger.warn("get_favorites: path does not exist: %s", path)
    end
  end

  -- Auto-expand ALL intermediate folders so the visual is "flat-ish"
  state.default_expanded_nodes = {}
  for id, _ in pairs(context.folders) do
    table.insert(state.default_expanded_nodes, id)
  end

  file_items.advanced_sort(root.children, state)
  renderer.show_nodes({ root }, state)

  state.loading = false
  logger.info("get_favorites: rendered %d favorites", #favorites)
end

return M
