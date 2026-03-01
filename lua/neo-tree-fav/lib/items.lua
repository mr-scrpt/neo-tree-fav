-- neo-tree-fav: Items builder for the favorites tree
-- Builds a FLAT top-level of favorited items using create_item for
-- correct node construction, then reparents them directly under root.
-- Directories are pre-scanned so standard toggle_node works.

local uv = vim.uv or vim.loop
local renderer = require("neo-tree.ui.renderer")
local file_items = require("neo-tree.sources.common.file-items")
local logger = require("neo-tree-fav.lib.logger")

local M = {}

-- ── Mock Data ──────────────────────────────────────────────────────────────

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

-- ── Collision Resolution ───────────────────────────────────────────────────

local function resolve_name_collisions(items, base_path)
  local name_groups = {}
  for _, item in ipairs(items) do
    local base = item.name
    name_groups[base] = name_groups[base] or {}
    table.insert(name_groups[base], item)
  end
  for name, group in pairs(name_groups) do
    if #group > 1 then
      for _, item in ipairs(group) do
        local parent_dir = vim.fn.fnamemodify(item.path, ":h")
        local relative = parent_dir:gsub("^" .. vim.pesc(base_path) .. "/", "")
        item.name = name .. " [" .. relative .. "]"
      end
    end
  end
end

-- ── Directory Scanner ──────────────────────────────────────────────────────

--- Recursively scan FS directory. Children are auto-parented under dir_path
--- by create_item's set_parents mechanism.
local function scan_directory_recursive(context, dir_path)
  local handle = uv.fs_scandir(dir_path)
  if not handle then return end

  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end

    local child_path = dir_path .. "/" .. name
    if not type then
      local stat = uv.fs_stat(child_path)
      type = stat and stat.type == "directory" and "directory" or "file"
    end

    local ok, item = pcall(file_items.create_item, context, child_path, type)
    if ok then
      item.extra = item.extra or {}
      if type == "directory" then
        item.loaded = true
        scan_directory_recursive(context, child_path)
      end
    end
  end
end

-- ── Main Entry Point ───────────────────────────────────────────────────────

--- Build the favorites tree with a FLAT top-level.
---
--- Strategy:
--- 1. create_item for each favorite path → builds full hierarchy via set_parents
--- 2. For favorite directories → scan real FS contents (children attach via set_parents)
--- 3. FLATTEN: replace root.children with ONLY the favorite items
---    - Each favorite's .children array stays intact (directories keep their subtree)
---    - Standard toggle_node works because directories have loaded=true + children
--- 4. Resolve name collisions with path hints
---@param state neotree.StateWithTree
M.get_favorites = function(state)
  if state.loading then return end
  state.loading = true

  local plugin_root = get_plugin_root()
  logger.debug("get_favorites: path=%s", state.path)

  local context = file_items.create_context()
  context.state = state

  -- Root
  local root = file_items.create_item(context, state.path, "directory")
  root.name = "Favorites"
  root.loaded = true
  root.search_pattern = state.search_pattern
  root.extra = root.extra or {}
  context.folders[root.path] = root

  -- Step 1+2: Create items & scan directories.
  -- create_item builds full intermediate hierarchy, which we'll discard.
  -- But the favorite items themselves and their subtrees remain correct.
  local favorite_items = {}
  local favorites = get_mock_favorites()

  for _, path in ipairs(favorites) do
    local stat = uv.fs_stat(path)
    if stat then
      local ftype = stat.type == "directory" and "directory" or "file"
      local ok, item = pcall(file_items.create_item, context, path, ftype)
      if ok then
        item.extra = item.extra or {}
        table.insert(favorite_items, item)
        if ftype == "directory" then
          item.loaded = true
          context.folders[path] = item
          scan_directory_recursive(context, path)
        end
      else
        logger.error("create_item failed: %s: %s", path, tostring(item))
      end
    else
      logger.warn("path not found: %s", path)
    end
  end

  -- Step 3: FLATTEN — replace root.children with only favorite items.
  -- Intermediate directories (my-project/, src/, core/, etc.) are discarded.
  -- Each favorite item keeps its own .children array intact.
  root.children = {}
  for _, item in ipairs(favorite_items) do
    item.parent_path = root.path
    table.insert(root.children, item)
  end

  -- Step 4: Collision resolution
  resolve_name_collisions(root.children, plugin_root)

  -- Auto-expand root only (favorites are top-level, user toggles them)
  state.default_expanded_nodes = { root.path }

  file_items.advanced_sort(root.children, state)
  renderer.show_nodes({ root }, state)

  state.loading = false
  logger.info("get_favorites: %d items rendered (flat)", #favorite_items)
end

return M
