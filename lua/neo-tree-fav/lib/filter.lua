-- neo-tree-fav: Filter/search for favorites source
-- Based on neo-tree's common/filters/init.lua but without filesystem dependencies.
-- The common module has hardcoded requires for filesystem.lib.filter_external
-- and reads config.filesystem.window.fuzzy_finder_mappings.
-- This module replaces those with source-agnostic logic.

local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local popups = require("neo-tree.ui.popups")
local renderer = require("neo-tree.ui.renderer")
local utils = require("neo-tree.utils")
local compat = require("neo-tree.utils._compat")
local log = require("neo-tree.log")
local manager = require("neo-tree.sources.manager")
local fzy = require("neo-tree.sources.common.filters.filter_fzy")

local M = {}

--- Reset filter state and navigate back to full tree.
---@param state neotree.State
---@param refresh boolean?
---@param focus_current boolean? Focus the currently selected node after reset
local function reset_filter(state, refresh, focus_current)
  if refresh == nil then refresh = true end

  -- Restore pre-search folder state
  if state.open_folders_before_search then
    state.force_open_folders = vim.deepcopy(state.open_folders_before_search, compat.noref())
  else
    state.force_open_folders = nil
  end
  state.open_folders_before_search = nil
  state.search_pattern = nil

  if focus_current then
    local success, node = pcall(state.tree.get_node, state.tree)
    if success and node then
      local id = node:get_id()
      renderer.position.set(state, id)
      id = utils.remove_trailing_slash(id)
      manager.navigate(state, nil, id, utils.wrap(pcall, renderer.focus_node, state, id, false))
    end
  elseif refresh then
    manager.navigate(state)
  else
    if state.orig_tree then
      state.tree = vim.deepcopy(state.orig_tree)
    end
  end
  state.orig_tree = nil
end

--- Reset search externally (called from commands.lua)
M.reset_search = function(state, refresh)
  reset_filter(state, refresh)
end

--- Show filtered tree by cloning orig_tree and removing non-matching nodes
local function show_filtered_tree(state, do_not_focus_window)
  state.tree = vim.deepcopy(state.orig_tree)
  state.tree:get_nodes()[1].search_pattern = state.search_pattern
  local max_score, max_id = fzy.get_score_min(), nil

  local function filter_tree(node_id)
    local node = state.tree:get_node(node_id)
    if not node then return false end
    local path = (node.extra and node.extra.search_path) or node.path or ""

    local should_keep = fzy.has_match(state.search_pattern, path)
    if should_keep then
      local score = fzy.score(state.search_pattern, path)
      if node.extra then
        node.extra.fzy_score = score
      end
      if score > max_score then
        max_score = score
        max_id = node_id
      end
    end

    if node:has_children() then
      for _, child_id in ipairs(node:get_child_ids()) do
        should_keep = filter_tree(child_id) or should_keep
      end
    end
    if not should_keep then
      state.tree:remove_node(node_id)
    end
    return should_keep
  end

  if #state.search_pattern > 0 then
    for _, root in ipairs(state.tree:get_nodes()) do
      filter_tree(root:get_id())
    end
  end
  manager.redraw(state.name)
  if max_id then
    renderer.focus_node(state, max_id, do_not_focus_window)
  end
end

--- Show filter input popup.
---@param state neotree.State
---@param search_as_you_type boolean?
---@param keep_filter_on_submit boolean?
M.show_filter = function(state, search_as_you_type, keep_filter_on_submit)
  local winid = vim.api.nvim_get_current_win()
  local height = vim.api.nvim_win_get_height(winid)
  local scroll_padding = 3

  local popup_msg = search_as_you_type and "Filter:" or "Search:"
  if state.config and state.config.title then
    popup_msg = state.config.title
  end

  local width = vim.fn.winwidth(0) - 2
  local row = height - 3
  if state.current_position == "float" then
    scroll_padding = 0
    width = vim.fn.winwidth(winid)
    row = height - 2
    vim.api.nvim_win_set_height(winid, row)
  end

  -- Save original tree for filtering
  state.orig_tree = vim.deepcopy(state.tree)

  local popup_options = popups.popup_options(popup_msg, width, {
    relative = "win",
    winid = winid,
    position = { row = row, col = 0 },
    size = width,
  })

  if not utils.truthy(state.open_folders_before_search) then
    state.open_folders_before_search = renderer.get_expanded_nodes(state.tree)
  end

  local waiting_for_default_value = utils.truthy(state.search_pattern)
  local input = Input(popup_options, {
    prompt = " ",
    default_value = state.search_pattern,
    on_submit = function(value)
      if value == "" then
        reset_filter(state)
        return
      end
      if search_as_you_type and not keep_filter_on_submit then
        -- Focus the matched node, clear filter
        reset_filter(state, true, true)
        return
      end
      -- Keep filter active
      state.search_pattern = value
      show_filtered_tree(state, false)
    end,
    on_change = function(value)
      if not search_as_you_type then return end

      if waiting_for_default_value then
        if #value < #state.search_pattern then return end
        waiting_for_default_value = false
      end
      if value == state.search_pattern or value == nil then return end

      state.search_pattern = value
      local len_to_delay = { [0] = 500, 500, 400, 200 }
      local delay = len_to_delay[#value] or 100

      utils.debounce(state.name .. "_filter", function()
        show_filtered_tree(state, true)
      end, delay, utils.debounce_strategy.CALL_LAST_ONLY)
    end,
  })

  input:mount()

  local restore_height = vim.schedule_wrap(function()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_set_height(winid, height)
    end
  end)

  local cmds = {
    move_cursor_down = function(_, _scroll_padding)
      renderer.focus_node(state, nil, true, 1, _scroll_padding)
    end,
    move_cursor_up = function(_, _scroll_padding)
      renderer.focus_node(state, nil, true, -1, _scroll_padding)
      vim.cmd("redraw!")
    end,
    close = function(_state)
      vim.cmd("stopinsert")
      input:unmount()
      if utils.truthy(_state.search_pattern) then
        reset_filter(_state, true)
      end
      restore_height()
    end,
    close_keep_filter = function(_state, _scroll_padding)
      keep_filter_on_submit = true
      cmds.close(_state, _scroll_padding)
    end,
    close_clear_filter = function(_state, _scroll_padding)
      keep_filter_on_submit = false
      cmds.close(_state, _scroll_padding)
    end,
  }

  -- Setup hooks (BufLeave/BufDelete → close)
  input:on(
    { event.BufLeave, event.BufDelete },
    utils.wrap(cmds.close, state, scroll_padding),
    { once = true }
  )

  -- Setup fuzzy_finder_mappings from neo-tree config
  -- Use favorites config if available, fall back to filesystem config
  local config = require("neo-tree").config
  local ff_mappings = {}
  if config.favorites and config.favorites.window and config.favorites.window.fuzzy_finder_mappings then
    ff_mappings = config.favorites.window.fuzzy_finder_mappings
  elseif config.filesystem and config.filesystem.window then
    ff_mappings = config.filesystem.window.fuzzy_finder_mappings or {}
  end

  -- Apply simple mappings (e.g., <down>=move_cursor_down, <up>=move_cursor_up)
  for lhs, rhs in pairs(ff_mappings) do
    if type(lhs) == "string" then
      local cmd = rhs
      if type(cmd) == "table" then
        if cmd.raw then
          input:map("i", lhs, cmd[1])
        else
          cmd = cmd[1]
        end
      end
      if type(cmd) == "string" and cmds[cmd] then
        input:map("i", lhs, utils.wrap(cmds[cmd], state, scroll_padding))
      elseif type(cmd) == "function" then
        input:map("i", lhs, utils.wrap(cmd, state, scroll_padding))
      end
    end
  end

  -- Apply mode-specific mappings (normal mode)
  for _, mappings_by_mode in ipairs(ff_mappings) do
    for mode, mappings in pairs(mappings_by_mode) do
      for lhs, rhs in pairs(mappings) do
        if type(lhs) == "string" then
          local cmd = rhs
          if type(cmd) == "string" and cmds[cmd] then
            input:map(mode, lhs, utils.wrap(cmds[cmd], state, scroll_padding))
          end
        end
      end
    end
  end
end

return M
