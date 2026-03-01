-- neo-tree-fav: Commands for the favorites source
-- Follows the buffers source pattern: delegate everything to common commands.

local cc = require("neo-tree.sources.common.commands")
local utils = require("neo-tree.utils")
local manager = require("neo-tree.sources.manager")

local M = {}

local refresh = utils.wrap(manager.refresh, "favorites")
local redraw = utils.wrap(manager.redraw, "favorites")

M.refresh = refresh

M.show_debug_info = cc.show_debug_info

-- Add ALL common commands: open, toggle_node, close_node, etc.
-- Standard toggle_node works because all directories have loaded=true
-- and have children populated during get_favorites().
cc._add_common_commands(M)

return M
