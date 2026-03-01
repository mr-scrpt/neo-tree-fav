-- neo-tree-fav: Commands for the favorites source
--
-- ARCHITECTURE:
--   REUSED from neo-tree:
--     • cc._add_common_commands(M) — open, toggle_node, close_node, copy, cut, paste, etc.
--       These work out of the box because our items use create_item with proper fields.
--
--   CUSTOM (source-specific, see lib/filter.lua for why):
--     • fuzzy_finder, filter_on_submit, fuzzy_sorter, clear_filter
--       These are NOT in common/commands — filesystem defines them in filesystem/commands.lua
--       with filesystem-specific filter.show_filter calls. We do the same with our filter module.

local cc = require("neo-tree.sources.common.commands")
local utils = require("neo-tree.utils")
local manager = require("neo-tree.sources.manager")
local filter = require("neo-tree-fav.lib.filter")

local M = {}

M.refresh = utils.wrap(manager.refresh, "favorites")
M.show_debug_info = cc.show_debug_info

-- ── Filter / Search Commands ───────────────────────────────────────────────
-- Modeled on filesystem/commands.lua:86-125.
-- Uses our lib/filter (not common/filters) for correct Enter behavior.

M.filter_as_you_type = function(state)
  filter.show_filter(state, true, false)
end

M.filter_on_submit = function(state)
  filter.show_filter(state, false, true)
end

M.fuzzy_finder = function(state)
  filter.show_filter(state, true, false)
end

M.fuzzy_sorter = function(state)
  filter.show_filter(state, true, false)
end

M.clear_filter = function(state)
  filter.reset_search(state, true)
end

-- ── Favorite Management ─────────────────────────────────────────────────────────

--- Toggle favorite (for use in filesystem source via F key)
M.toggle_favorite = function(state)
  local node = state.tree:get_node()
  if not node or node.type == "message" then return end
  local path = node:get_id()
  local storage = require("neo-tree-fav.lib.storage")
  local added = storage.toggle(path)
  local action = added and "Added to" or "Removed from"
  vim.notify(action .. " favorites: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
  -- Refresh favorites source if open
  pcall(manager.refresh, "favorites")
end

--- Remove favorite (for use in favorites tab — remove selected item)
M.remove_favorite = function(state)
  local node = state.tree:get_node()
  if not node or node.type == "message" then return end
  local path = node:get_id()
  local storage = require("neo-tree-fav.lib.storage")
  storage.remove(path)
  vim.notify("Removed from favorites: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
  manager.refresh("favorites")
end

-- ── Common Commands ────────────────────────────────────────────────────────
-- Adds: open, toggle_node, close_node, close_all_nodes, expand_all_nodes,
-- copy, cut, paste, delete, rename, show_debug_info, etc.
cc._add_common_commands(M)

return M
