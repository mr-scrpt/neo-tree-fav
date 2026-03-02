-- neo-tree-fav: Per-project storage for favorite paths
--
-- Stores favorites in a JSON file per project.
-- Default: stdpath("data")/neo-tree-favorites/{project_name}_{hash}.json
--
-- Simple read-from-disk on every call (no in-memory cache).
-- File is small (~50 paths max), so sync IO is fine.

local logger = require("neo-tree-fav.lib.logger")

local M = {}

--- Get the storage directory, with migration from old location.
---@return string
local function get_storage_dir()
  local config = require("neo-tree-fav.lib.config")
  local new_dir = config.options.storage_dir

  -- Migration: check if old location has files
  local old_dir = vim.fn.stdpath("config") .. "/favorite-projects"
  if new_dir ~= old_dir and vim.fn.isdirectory(old_dir) == 1 then
    local old_files = vim.fn.glob(old_dir .. "/*.json", false, true)
    if #old_files > 0 then
      -- Old location has data — check if new location is empty/missing
      local new_files = vim.fn.glob(new_dir .. "/*.json", false, true)
      if #new_files == 0 then
        -- Use old location (user hasn't migrated yet)
        return old_dir
      end
    end
  end

  vim.fn.mkdir(new_dir, "p")
  return new_dir
end

--- Get the storage file path for the current project.
---@return string
M.get_storage_path = function()
  local cwd = vim.fn.getcwd()
  local project_name = vim.fn.fnamemodify(cwd, ":t")
  local cwd_hash = vim.fn.sha256(cwd):sub(1, 8)
  local dir = get_storage_dir()
  return dir .. "/" .. project_name .. "_" .. cwd_hash .. ".json"
end

--- Load favorites from disk.
---@return string[] Absolute paths
M.load = function()
  local path = M.get_storage_path()
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok or #content == 0 then
    return {}
  end
  local decode_ok, data = pcall(vim.fn.json_decode, content[1])
  if not decode_ok or type(data) ~= "table" then
    logger.warn("Corrupted storage file: %s", path)
    return {}
  end
  return data
end

--- Alias for load().
---@return string[]
M.get = M.load

--- Save favorites to disk.
---@param paths string[]
M.save = function(paths)
  local file_path = M.get_storage_path()
  local ok, err = pcall(vim.fn.writefile, { vim.fn.json_encode(paths) }, file_path)
  if not ok then
    logger.error("Failed to save favorites: %s", tostring(err))
  end
end

--- Add a path to favorites (if not already present).
---@param path string Absolute path
M.add = function(path)
  local paths = M.load()
  for _, p in ipairs(paths) do
    if p == path then return end
  end
  table.insert(paths, path)
  M.save(paths)
end

--- Remove a path from favorites.
---@param path string Absolute path
M.remove = function(path)
  local paths = M.load()
  local new = {}
  for _, p in ipairs(paths) do
    if p ~= path then
      table.insert(new, p)
    end
  end
  M.save(new)
end

--- Toggle a path in favorites.
---@param path string Absolute path
---@return boolean added true if added, false if removed
M.toggle = function(path)
  local paths = M.load()
  for i, p in ipairs(paths) do
    if p == path then
      table.remove(paths, i)
      M.save(paths)
      return false
    end
  end
  table.insert(paths, path)
  M.save(paths)
  return true
end

--- Check if a path is in favorites.
---@param path string Absolute path
---@return boolean
M.has = function(path)
  local paths = M.load()
  for _, p in ipairs(paths) do
    if p == path then return true end
  end
  return false
end

--- Remove all paths that no longer exist on disk.
---@return number count Number of removed entries
M.clean_missing = function()
  local uv = vim.uv or vim.loop
  local paths = M.load()
  local clean = {}
  local removed = 0
  for _, p in ipairs(paths) do
    if uv.fs_stat(p) then
      table.insert(clean, p)
    else
      removed = removed + 1
    end
  end
  if removed > 0 then
    M.save(clean)
  end
  return removed
end

return M
