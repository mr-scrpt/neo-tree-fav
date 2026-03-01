-- neo-tree-fav: Items builder for the favorites tree
-- Follows the pattern from git_status/lib/items.lua

local renderer = require("neo-tree.ui.renderer")
local file_items = require("neo-tree.sources.common.file-items")
local logger = require("neo-tree-fav.lib.logger")

local M = {}

--- Build and render the favorites tree.
--- Currently a stub that shows an empty root node.
---@param state neotree.StateWithTree
M.get_favorites = function(state)
  if state.loading then
    return
  end
  state.loading = true
  logger.debug("get_favorites: building tree for path=%s", state.path)

  local context = file_items.create_context()
  context.state = state

  -- Create root folder
  local root = file_items.create_item(context, state.path, "directory") --[[@as neotree.FileItem.Directory]]
  root.name = "Favorites"
  root.loaded = true
  root.search_pattern = state.search_pattern
  context.folders[root.path] = root

  -- TODO: Phase 2 will add items from mock data here

  state.default_expanded_nodes = {}
  for id, _ in pairs(context.folders) do
    table.insert(state.default_expanded_nodes, id)
  end

  file_items.advanced_sort(root.children, state)
  renderer.show_nodes({ root }, state)

  state.loading = false
  logger.info("get_favorites: tree rendered with %d top-level items", #root.children)
end

return M
