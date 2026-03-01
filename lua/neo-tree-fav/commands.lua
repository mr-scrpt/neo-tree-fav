-- neo-tree-fav: Commands for the favorites source
-- Reuses common commands and adds favorites-specific ones

local cc = require("neo-tree.sources.common.commands")
local utils = require("neo-tree.utils")
local manager = require("neo-tree.sources.manager")

---@class neotree.sources.Favorites.Commands : neotree.sources.Common.Commands
local M = {}

local refresh = utils.wrap(manager.refresh, "favorites")
local redraw = utils.wrap(manager.redraw, "favorites")

-- Standard commands delegated to common
M.refresh = refresh

M.copy_to_clipboard = function(state)
  cc.copy_to_clipboard(state, redraw)
end

---@type neotree.TreeCommandVisual
M.copy_to_clipboard_visual = function(state, selected_nodes)
  cc.copy_to_clipboard_visual(state, selected_nodes, redraw)
end

M.cut_to_clipboard = function(state)
  cc.cut_to_clipboard(state, redraw)
end

---@type neotree.TreeCommandVisual
M.cut_to_clipboard_visual = function(state, selected_nodes)
  cc.cut_to_clipboard_visual(state, selected_nodes, redraw)
end

M.paste_from_clipboard = function(state)
  cc.paste_from_clipboard(state, refresh)
end

M.clear_clipboard = function(state)
  cc.clear_clipboard(state)
  redraw()
end

M.copy = function(state)
  cc.copy(state, redraw)
end

M.move = function(state)
  cc.move(state, redraw)
end

M.delete = function(state)
  cc.delete(state, refresh)
end

M.rename = function(state)
  cc.rename(state, refresh)
end

M.show_debug_info = cc.show_debug_info

-- Add all common commands (open, close_node, toggle_node, etc.)
cc._add_common_commands(M)

return M
