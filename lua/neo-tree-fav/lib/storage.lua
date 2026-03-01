-- neo-tree-fav: Storage module for favorites persistence
-- Handles reading/writing JSON per-project files

local logger = require("neo-tree-fav.lib.logger")

local M = {}

--- Get the storage directory path
---@return string
M.get_storage_dir = function()
  return vim.fn.stdpath("config") .. "/favorite-projects"
end

--- Generate a unique filename for the current project
---@return string
M.get_project_filename = function()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")
  -- Simple hash of the full path to avoid collisions
  local hash = vim.fn.sha256(cwd):sub(1, 8)
  return project_name .. "_" .. hash .. ".json"
end

--- Load favorites for the current project
---@return string[] List of absolute paths
M.load = function()
  -- TODO: Implement in Phase 4
  logger.debug("storage.load: stub called")
  return {}
end

--- Save favorites for the current project
---@param paths string[] List of absolute paths
M.save = function(paths)
  -- TODO: Implement in Phase 4
  logger.debug("storage.save: stub called with %d paths", #paths)
end

return M
