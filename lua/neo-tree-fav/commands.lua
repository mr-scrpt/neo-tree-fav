-- neo-tree-fav: Commands for the favorites source
-- Wires filter/search commands using our filter module
-- (modeled on filesystem/lib/filter.lua pattern).

local cc = require("neo-tree.sources.common.commands")
local utils = require("neo-tree.utils")
local manager = require("neo-tree.sources.manager")
local filter = require("neo-tree-fav.lib.filter")

local M = {}

local refresh = utils.wrap(manager.refresh, "favorites")
local redraw = utils.wrap(manager.redraw, "favorites")

M.refresh = refresh
M.show_debug_info = cc.show_debug_info

-- ── Filter / Search Commands ───────────────────────────────────────────────

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

-- Add ALL common commands: open, toggle_node, close_node, etc.
cc._add_common_commands(M)

return M
