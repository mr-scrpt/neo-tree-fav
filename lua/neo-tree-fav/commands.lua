-- neo-tree-fav: Commands for the favorites source
-- Reuses common commands, wires toggle_directory for folder expansion

local cc = require("neo-tree.sources.common.commands")
local utils = require("neo-tree.utils")
local manager = require("neo-tree.sources.manager")
local fav = require("neo-tree-fav")

---@class neotree.sources.Favorites.Commands : neotree.sources.Common.Commands
local M = {}

local refresh = utils.wrap(manager.refresh, "favorites")
local redraw = utils.wrap(manager.redraw, "favorites")

--- Create a toggle_directory callback bound to the current state.
--- This follows the filesystem pattern: each command creates a fresh
--- wrapper with `state` pre-applied.
---@param state neotree.State
---@return function
local function make_toggle_dir(state)
  return utils.wrap(fav.toggle_directory, state)
end

-- Open commands — pass toggle_directory so directories expand instead of "open"
M.open = function(state)
  cc.open(state, make_toggle_dir(state))
end

M.open_split = function(state)
  cc.open_split(state, make_toggle_dir(state))
end

M.open_vsplit = function(state)
  cc.open_vsplit(state, make_toggle_dir(state))
end

M.open_tabnew = function(state)
  cc.open_tabnew(state, make_toggle_dir(state))
end

M.open_drop = function(state)
  cc.open_drop(state, make_toggle_dir(state))
end

M.open_tab_drop = function(state)
  cc.open_tab_drop(state, make_toggle_dir(state))
end

M.open_with_window_picker = function(state)
  cc.open_with_window_picker(state, make_toggle_dir(state))
end

M.toggle_node = function(state)
  cc.toggle_node(state, make_toggle_dir(state))
end

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

-- Add all common commands (close_node, close_all_nodes, etc.)
cc._add_common_commands(M)

return M
