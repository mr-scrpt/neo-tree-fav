-- neo-tree-fav: Items builder for the favorites tree
-- Builds a FLAT top-level list of favorited files/directories,
-- with recursive expansion for directories via uv.fs_scandir.

local uv = vim.uv or vim.loop
local renderer = require("neo-tree.ui.renderer")
local file_items = require("neo-tree.sources.common.file-items")
local utils = require("neo-tree.utils")
local logger = require("neo-tree-fav.lib.logger")

local M = {}

-- ── Mock Data ──────────────────────────────────────────────────────────────

--- Get the plugin's installation directory (where lua/neo-tree-fav/ lives).
--- We derive this from the current file's path, NOT from vim.fn.getcwd()
--- because CWD can change when neo-tree filesystem has bind_to_cwd = true.
---@return string
local function get_plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2) -- remove leading @
  -- source = .../neo-tree-fav/lua/neo-tree-fav/lib/items.lua
  -- plugin root = .../neo-tree-fav
  return vim.fn.fnamemodify(source, ":h:h:h:h")
end

local function get_mock_favorites()
  local root = get_plugin_root()
  return {
    -- Files
    { path = root .. "/my-project/src/core/domain/aggregate-root.ts",                type = "file" },
    { path = root .. "/my-project/src/core/domain/value-object.ts",                  type = "file" },
    { path = root .. "/my-project/src/modules/users/domain/entities/user.entity.ts", type = "file" },
    { path = root .. "/my-project/infrastructure/database/prisma/schema.prisma",     type = "file" },
    -- Папки
    { path = root .. "/my-project/infrastructure/database/migrations",               type = "directory" },
  }
end

-- ── Collision Resolution ───────────────────────────────────────────────────

--- Resolve name collisions among items list.
--- Items with duplicate basenames get path hints: `name [relative/path/]`
---@param items table[] List of items (each with .name and .path)
---@param base_path string Base path for computing relative hints
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
        logger.debug("collision resolved: %s -> %s", name, item.name)
      end
    end
  end
end

-- ── Directory Expansion ────────────────────────────────────────────────────

--- Recursively scan a real directory and add children via create_item.
--- Children are properly parented under the directory item via create_item's set_parents.
---@param context table The file_items context
---@param dir_path string Absolute path to directory
---@param state table Neo-tree state
local function scan_directory(context, dir_path, state)
  local handle = uv.fs_scandir(dir_path)
  if not handle then
    logger.warn("scan_directory: cannot read %s", dir_path)
    return
  end

  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then
      break
    end

    local child_path = dir_path .. "/" .. name
    -- Default to "file" if type is nil
    if not type then
      local stat = uv.fs_stat(child_path)
      type = stat and stat.type == "directory" and "directory" or "file"
    end

    local success, item = pcall(file_items.create_item, context, child_path, type)
    if success then
      if type == "directory" then
        -- Recursively expand if user has opened this subdirectory
        if state.explicitly_opened_directories
          and state.explicitly_opened_directories[child_path] then
          item.loaded = true
          scan_directory(context, child_path, state)
        end
      end
    else
      logger.error("scan_directory: error creating item %s: %s", child_path, tostring(item))
    end
  end
end

-- ── Main Entry Point ───────────────────────────────────────────────────────

--- Build and render the favorites tree from mock data.
--- Creates a FLAT top-level: each favorite is a direct child of root,
--- regardless of its actual filesystem depth.
---@param state neotree.StateWithTree
M.get_favorites = function(state)
  if state.loading then
    return
  end
  state.loading = true

  local plugin_root = get_plugin_root()
  logger.debug("get_favorites: building tree for path=%s", state.path)

  -- Phase 1: Create all items using standard create_item (which builds
  -- full hierarchy). We use a temporary context for this.
  local context = file_items.create_context()
  context.state = state

  -- Create root folder
  local root = file_items.create_item(context, state.path, "directory")
  root.name = "Favorites"
  root.loaded = true
  root.search_pattern = state.search_pattern
  context.folders[root.path] = root

  -- Create favorite items. create_item will auto-create intermediate
  -- parent directories via set_parents, which we'll discard.
  local favorites = get_mock_favorites()
  local favorite_items = {}

  for _, fav in ipairs(favorites) do
    local success, item = pcall(file_items.create_item, context, fav.path, fav.type)
    if success then
      table.insert(favorite_items, item)
      if fav.type == "directory" then
        -- Register as folder for children to attach to
        context.folders[fav.path] = item
        -- If user has expanded this directory, scan its contents
        if state.explicitly_opened_directories
          and state.explicitly_opened_directories[fav.path] then
          item.loaded = true
          scan_directory(context, fav.path, state)
        end
      end
    else
      logger.error("get_favorites: error creating item %s: %s", fav.path, tostring(item))
    end
  end

  -- Phase 2: FLATTEN — replace root.children with only the favorite items.
  -- This discards all intermediate directories that create_item built.
  root.children = {}
  for _, item in ipairs(favorite_items) do
    item.parent_path = root.path
    table.insert(root.children, item)
  end

  -- Phase 3: Resolve name collisions on the flat list
  resolve_name_collisions(root.children, plugin_root)

  -- Only root expanded by default
  state.default_expanded_nodes = { root.path }

  file_items.advanced_sort(root.children, state)
  renderer.show_nodes({ root }, state)

  state.loading = false
  logger.info("get_favorites: tree rendered with %d top-level items", #root.children)
end

return M
