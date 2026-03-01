-- neo-tree-fav: Commands for the favorites source
-- Uses common/filters for filter/search functionality.

local cc = require("neo-tree.sources.common.commands")
local utils = require("neo-tree.utils")
local manager = require("neo-tree.sources.manager")
local common_filter = require("neo-tree.sources.common.filters")

local M = {}

local refresh = utils.wrap(manager.refresh, "favorites")
local redraw = utils.wrap(manager.redraw, "favorites")

M.refresh = refresh
M.show_debug_info = cc.show_debug_info

-- ── Filter / Search Commands ───────────────────────────────────────────────
-- common/filters.show_filter is generic: uses manager.navigate(state)
-- for reset and manager.redraw(state.name) for live updates.

M.filter_as_you_type = function(state)
  common_filter.show_filter(state, true, false)
end

M.filter_on_submit = function(state)
  common_filter.show_filter(state, false, true)
end

M.fuzzy_finder = function(state)
  common_filter.show_filter(state, true, false)
end

M.fuzzy_sorter = function(state)
  common_filter.show_filter(state, true, false)
end

M.clear_filter = function(state)
  state.search_pattern = nil
  state.orig_tree = nil
  manager.navigate(state)
end

-- Add ALL common commands: open, toggle_node, close_node, etc.
cc._add_common_commands(M)

return M
