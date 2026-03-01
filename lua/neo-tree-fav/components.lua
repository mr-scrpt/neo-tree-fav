-- neo-tree-fav: Components for rendering favorites tree nodes
-- Extends common components with favorites-specific rendering

local highlights = require("neo-tree.ui.highlights")
local common = require("neo-tree.sources.common.components")

---@type table<string, neotree.Renderer>
local M = {}

--- Custom name component for favorites:
--- - Root node shows "FAVORITES" header
--- - All other nodes use standard name rendering
M.name = function(config, node, state)
  local highlight = config.highlight or highlights.FILE_NAME
  local name = node.name

  if node.type == "directory" then
    if node:get_depth() == 1 then
      highlight = highlights.ROOT_NAME
      name = "FAVORITES"
    else
      highlight = highlights.DIRECTORY_NAME
    end
  elseif config.use_git_status_colors then
    local git_status = state.components.git_status({}, node, state)
    if git_status and git_status.highlight then
      highlight = git_status.highlight
    end
  end

  return {
    text = name,
    highlight = highlight,
  }
end

return vim.tbl_deep_extend("force", common, M)
