-- neo-tree-fav: Filter/search for favorites source
--
-- ARCHITECTURE:
--   Hybrid approach — reuses neo-tree internals where possible, custom only where needed.
--
--   REUSED from neo-tree (stable public APIs):
--     • fzy (common.filters.filter_fzy) — fuzzy scoring and matching
--     • setup_hooks (common.filters) — BufLeave/BufDelete auto-close handlers
--     • setup_mappings (common.filters) — ↑↓ Esc keybindings from fuzzy_finder_mappings
--     • nui.input + popups — UI primitives
--     • renderer.focus_node, renderer.position, renderer.get_expanded_nodes
--     • utils.open_file, utils.debounce, utils.remove_trailing_slash
--
--   CUSTOM (cannot use common/filters.show_filter directly — see below):
--     • show_filter — common/filters.show_filter hardcodes:
--       • show_filtered_tree (clone+remove_node — broken for non-filesystem sources)
--       • filter_external.cancel() in reset_filter (filesystem-only)
--       Our on_change instead calls fav.navigate(state) to rebuild the tree,
--       matching the filesystem pattern (_navigate_internal on each keypress).
--     • reset_search — filesystem/init.lua:202-248 pattern:
--       file → utils.open_file, dir → navigate+focus
--       (common/filters.reset_filter only navigates, never opens files)
--
-- REFERENCES:
--   • neo-tree/sources/common/filters/init.lua — our setup_hooks/setup_mappings source
--   • neo-tree/sources/filesystem/lib/filter.lua — our show_filter UI pattern
--   • neo-tree/sources/filesystem/init.lua:202-248 — our reset_search pattern

local Input = require("nui.input")
local fav = require("neo-tree-fav")
local popups = require("neo-tree.ui.popups")
local renderer = require("neo-tree.ui.renderer")
local utils = require("neo-tree.utils")
local log = require("neo-tree.log")
local manager = require("neo-tree.sources.manager")
local compat = require("neo-tree.utils._compat")
local common_filter = require("neo-tree.sources.common.filters")

local M = {}

--- Reset search state and handle the selected node.
--- Matches filesystem/init.lua:reset_search (lines 202-248) EXACTLY:
---   - file → utils.open_file
---   - directory → navigate + focus
M.reset_search = function(state, refresh, open_current_node)
  log.trace("favorites: reset_search")

  -- Reset search state
  if state.open_folders_before_search then
    state.force_open_folders = vim.deepcopy(state.open_folders_before_search, compat.noref())
  else
    state.force_open_folders = nil
  end
  state.search_pattern = nil
  state.open_folders_before_search = nil

  if open_current_node then
    local success, node = pcall(state.tree.get_node, state.tree)
    if success and node then
      local path = node:get_id()
      renderer.position.set(state, path)
      if node.type == "directory" then
        path = utils.remove_trailing_slash(path)
        fav.navigate(state, nil, path, function()
          pcall(renderer.focus_node, state, path, false)
        end)
      else
        -- FILE: open it directly (matches filesystem behavior)
        utils.open_file(state, path)
        if
          refresh
          and state.current_position ~= "current"
          and state.current_position ~= "float"
        then
          fav.navigate(state, nil, path)
        end
      end
    end
  else
    if refresh then
      fav.navigate(state)
    end
  end
  state.orig_tree = nil
end

M.show_filter = function(state, search_as_you_type, keep_filter_on_submit)
  local winid = vim.api.nvim_get_current_win()
  local height = vim.api.nvim_win_get_height(winid)
  local scroll_padding = 3
  local popup_options
  local popup_msg = search_as_you_type and "Filter:" or "Search:"

  if state.current_position == "float" then
    scroll_padding = 0
    local width = vim.fn.winwidth(winid)
    local row = height - 2
    vim.api.nvim_win_set_height(winid, row)
    popup_options = popups.popup_options(popup_msg, width, {
      relative = "win",
      winid = winid,
      position = { row = row, col = 0 },
      size = width,
    })
  else
    local width = vim.fn.winwidth(0) - 2
    local row = height - 3
    popup_options = popups.popup_options(popup_msg, width, {
      relative = "win",
      winid = winid,
      position = { row = row, col = 0 },
      size = width,
    })
  end

  -- Save original tree for clone-and-filter
  state.orig_tree = vim.deepcopy(state.tree)

  if not utils.truthy(state.open_folders_before_search) then
    state.open_folders_before_search = renderer.get_expanded_nodes(state.tree)
  end

  local waiting_for_default_value = utils.truthy(state.search_pattern)
  local input = Input(popup_options, {
    prompt = " ",
    default_value = state.search_pattern,
    on_submit = function(value)
      if value == "" then
        M.reset_search(state)
        return
      end
      if search_as_you_type and not keep_filter_on_submit then
        -- Filesystem pattern: reset search, open file or focus directory
        M.reset_search(state, true, true)
        return
      end
      state.search_pattern = value
      fav.navigate(state)
    end,
    on_change = function(value)
      if not search_as_you_type then return end
      if waiting_for_default_value then
        if #value < #state.search_pattern then return end
        waiting_for_default_value = false
      end
      if value == state.search_pattern or value == nil then return end

      if value == "" then
        if state.search_pattern == nil then return end
        local original_open_folders = nil
        if type(state.open_folders_before_search) == "table" then
          original_open_folders = vim.deepcopy(state.open_folders_before_search, compat.noref())
        end
        M.reset_search(state)
        state.open_folders_before_search = original_open_folders
      else
        state.search_pattern = value
        local len_to_delay = { [0] = 500, 500, 400, 200 }
        local delay = len_to_delay[#value] or 100

        utils.debounce("favorites_filter", function()
          fav.navigate(state)
        end, delay, utils.debounce_strategy.CALL_LAST_ONLY)
      end
    end,
  })

  input:mount()

  local restore_height = vim.schedule_wrap(function()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_set_height(winid, height)
    end
  end)

  local cmds
  cmds = {
    move_cursor_down = function(_state, _scroll_padding)
      renderer.focus_node(_state, nil, true, 1, _scroll_padding)
    end,
    move_cursor_up = function(_state, _scroll_padding)
      renderer.focus_node(_state, nil, true, -1, _scroll_padding)
      vim.cmd("redraw!")
    end,
    close = function(_state, _scroll_padding)
      vim.cmd("stopinsert")
      input:unmount()
      -- Filesystem pattern: defer to avoid double-reset if on_submit already ran
      vim.defer_fn(function()
        if utils.truthy(state.search_pattern) and not keep_filter_on_submit then
          M.reset_search(state, true)
        end
      end, 100)
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

  common_filter.setup_hooks(input, cmds, state, scroll_padding)
  common_filter.setup_mappings(input, cmds, state, scroll_padding)
end

return M
