-- neo-tree-fav: Custom "favorites" source for neo-tree.nvim
-- Entry point — implements the neo-tree Source contract

local manager = require("neo-tree.sources.manager")
local renderer = require("neo-tree.ui.renderer")
local events = require("neo-tree.events")
local utils = require("neo-tree.utils")
local items = require("neo-tree-fav.lib.items")
local logger = require("neo-tree-fav.lib.logger")

---@class neotree.sources.Favorites : neotree.Source
local M = {
  name = "favorites",
  display_name = " ⭐ Favorites ",
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
--- May also be called by lazy.nvim with no arguments — in that case, just init logger.
---@param config table?
---@param global_config table?
M.setup = function(config, global_config)
  logger.init()
  logger.info("favorites source setup complete")

  -- When called from lazy.nvim without args, just init logger and return.
  -- Neo-tree will call setup again with proper config.
  if not global_config then
    return
  end

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

  -- Register "F" toggle in filesystem source via autocmd.
  -- We set a buffer-local keymap on every neo-tree filesystem buffer.
  -- This is the most reliable approach — it works regardless of when
  -- neo-tree processes its config, because we set the keymap AFTER
  -- the buffer is created.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    group = vim.api.nvim_create_augroup("neo-tree-fav-toggle", { clear = true }),
    callback = function(args)
      -- Check if this buffer belongs to the filesystem source
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(args.buf) then return end
        local ok, source = pcall(vim.api.nvim_buf_get_var, args.buf, "neo_tree_source")
        if ok and source == "filesystem" then
          vim.api.nvim_buf_set_keymap(args.buf, "n", "F", "", {
            noremap = true,
            nowait = true,
            desc = "Toggle favorite",
            callback = function()
              -- Get state for this filesystem buffer
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

  -- ── ⭐ Indicator in Filesystem ─────────────────────────────────────────
  -- Inject favorite_indicator component into filesystem source so
  -- users can add { "favorite_indicator" } to their renderers config.
  -- The component checks storage.has(path) and shows ⭐ for favorited items.
  vim.api.nvim_set_hl(0, "NeoTreeFavorite", { fg = "#FFD700", default = true })

  local ok_fs, fs_components = pcall(require, "neo-tree.sources.filesystem.components")
  if ok_fs then
    fs_components.favorite_indicator = function(config, node, state)
      local storage = require("neo-tree-fav.lib.storage")
      local path = node.path or node:get_id()
      if storage.has(path) then
        return {
          text = "⭐ ",
          highlight = config.highlight or "NeoTreeFavorite",
        }
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
