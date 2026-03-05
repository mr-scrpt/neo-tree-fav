-- neo-tree-fav: Custom "favorites" source for neo-tree.nvim
-- Entry point — implements the neo-tree Source contract

local manager = require("neo-tree.sources.manager")
local renderer = require("neo-tree.ui.renderer")
local events = require("neo-tree.events")
local utils = require("neo-tree.utils")
local items = require("neo-tree-fav.lib.items")
local logger = require("neo-tree-fav.lib.logger")
local plugin_config = require("neo-tree-fav.lib.config")

---@class neotree.sources.Favorites : neotree.Source
local M = {
  name = "favorites",
  display_name = plugin_config.options.display_name,
}

local wrap = function(func)
  return utils.wrap(func, M.name)
end

local get_state = function()
  return manager.get_state(M.name)
end

--- Navigate to the given path.
---@param state neotree.State
---@param path string? Path to navigate to. If empty, will navigate to the cwd.
---@param path_to_reveal string?
---@param callback function?
---@param async boolean?
M.navigate = function(state, path, path_to_reveal, callback, async)
  state.dirty = false
  if path == nil then
    path = vim.fn.getcwd()
  end
  state.path = path

  if path_to_reveal then
    renderer.position.set(state, path_to_reveal)
  end

  logger.debug("navigate: path=%s, path_to_reveal=%s", state.path, tostring(path_to_reveal))
  items.get_favorites(state)

  if type(callback) == "function" then
    vim.schedule(callback)
  end
end

M.refresh = function()
  manager.refresh(M.name)
end

--- Default configuration for this source.
--- Will be merged into neo-tree defaults.
M.default_config = {
  renderers = {
    directory = {
      { "indent" },
      { "icon" },
      {
        "container",
        content = {
          { "name", zindex = 10 },
          { "clipboard", zindex = 10 },
          { "diagnostics", errors_only = true, zindex = 20, align = "right", hide_when_expanded = true },
          { "git_status", zindex = 10, align = "right", hide_when_expanded = true },
        },
      },
    },
    file = {
      { "indent" },
      { "icon" },
      {
        "container",
        content = {
          { "name", zindex = 10 },
          { "clipboard", zindex = 10 },
          { "modified", zindex = 20, align = "right" },
          { "diagnostics", zindex = 20, align = "right" },
          { "git_status", zindex = 10, align = "right" },
        },
      },
    },
    message = {
      { "indent", with_markers = false },
      { "name", highlight = "NeoTreeMessage" },
    },
  },
  window = {
    mappings = {
      ["/"] = "fuzzy_finder",
      ["f"] = "filter_on_submit",
      ["#"] = "fuzzy_sorter",
      ["<C-x>"] = "clear_filter",
      ["F"] = "remove_favorite",
      ["X"] = "clean_missing",
    },
  },
}

---Configures the plugin, should be called before the plugin is used.
--- Called by neo-tree's manager.setup() with (config, global_config).
--- May also be called by lazy.nvim with user opts — in that case, apply config and return.
---@param config table?
---@param global_config table?
M.setup = function(config, global_config)
  -- When called from lazy.nvim: setup(user_opts)
  -- Apply user options and register keymap, but don't subscribe to neo-tree events yet.
  if not global_config then
    plugin_config.setup(config)
    M.display_name = plugin_config.options.display_name
    logger.init()
    logger.info("favorites plugin configured via setup()")

    -- Register keymap for opening favorites float
    if plugin_config.options.keymap then
      vim.keymap.set("n", plugin_config.options.keymap, function()
        vim.cmd("Neotree float favorites")
      end, { desc = "Toggle Favorites (float)" })
    end
    return
  end

  logger.init()
  logger.info("favorites source setup complete")

  -- Refresh on write
  if global_config.enable_refresh_on_write then
    manager.subscribe(M.name, {
      event = events.VIM_BUFFER_CHANGED,
      handler = function(args)
        if utils.is_real_file(args.afile) then
          M.refresh()
        end
      end,
    })
  end

  -- Register toggle key in filesystem source via autocmd.
  local toggle_key = plugin_config.options.filesystem_toggle_key
  if toggle_key then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "neo-tree",
      group = vim.api.nvim_create_augroup("neo-tree-fav-toggle", { clear = true }),
      callback = function(args)
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then return end
          local ok, source = pcall(vim.api.nvim_buf_get_var, args.buf, "neo_tree_source")
          if ok and source == "filesystem" then
            vim.api.nvim_buf_set_keymap(args.buf, "n", toggle_key, "", {
              noremap = true,
              nowait = true,
              desc = "Toggle favorite",
              callback = function()
                local mgr = require("neo-tree.sources.manager")
                local state = mgr.get_state("filesystem")
                if state then
                  require("neo-tree-fav.commands").toggle_favorite(state)
                end
              end,
            })
          end
        end)
      end,
    })
  end

  -- ── ⭐ Indicator in Filesystem ─────────────────────────────────────────
  local ind = plugin_config.options.indicator
  if ind.enabled then
    vim.api.nvim_set_hl(0, ind.highlight, { fg = ind.highlight_color, default = true })

    local ok_fs, fs_components = pcall(require, "neo-tree.sources.filesystem.components")
    if ok_fs then
      fs_components.favorite_indicator = function(comp_config, node, state)
        local storage = require("neo-tree-fav.lib.storage")
        local path = node.path or node:get_id()
        if storage.has(path) then
          return {
            text = ind.icon,
            highlight = comp_config.highlight or ind.highlight,
          }
        end
        return { text = "" }
      end
    end
  end

  -- Diagnostics support
  if global_config.enable_diagnostics then
    manager.subscribe(M.name, {
      event = events.STATE_CREATED,
      handler = function(state)
        state.diagnostics_lookup = utils.get_diagnostic_counts()
      end,
    })
    manager.subscribe(M.name, {
      event = events.VIM_DIAGNOSTIC_CHANGED,
      handler = wrap(manager.diagnostics_changed),
    })
  end

  -- Modified markers support
  if global_config.enable_modified_markers then
    manager.subscribe(M.name, {
      event = events.VIM_BUFFER_MODIFIED_SET,
      handler = wrap(manager.opened_buffers_changed),
    })
  end
end

return M
