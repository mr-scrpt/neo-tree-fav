-- neo-tree-fav: Logger module
-- Writes structured logs to a dedicated file for debugging

local M = {}

---@type string
local log_path = nil

---@type boolean
local initialized = false

--- Get the log file path
---@return string
local function get_log_path()
  if not log_path then
    log_path = vim.fn.stdpath("config") .. "/neo-tree-favorites.log"
  end
  return log_path
end

--- Format a timestamp
---@return string
local function timestamp()
  return os.date("%Y-%m-%d %H:%M:%S")
end

--- Write a line to the log file
---@param level string
---@param msg string
---@param ... any
local function write(level, msg, ...)
  if not initialized then
    return
  end
  local formatted = string.format(msg, ...)
  local line = string.format("[%s] [%s] %s\n", timestamp(), level, formatted)
  local f = io.open(get_log_path(), "a")
  if f then
    f:write(line)
    f:close()
  end
end

--- Initialize the logger — truncates the log file
M.init = function()
  local path = get_log_path()
  -- Ensure parent directory exists
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  -- Truncate the file
  local f = io.open(path, "w")
  if f then
    f:write(string.format("[%s] [INFO] Logger initialized. File: %s\n", timestamp(), path))
    f:close()
  end
  initialized = true
end

--- Log an info message
---@param msg string Format string
---@param ... any Format arguments
M.info = function(msg, ...)
  write("INFO", msg, ...)
end

--- Log a debug message
---@param msg string Format string
---@param ... any Format arguments
M.debug = function(msg, ...)
  write("DEBUG", msg, ...)
end

--- Log a warning message
---@param msg string Format string
---@param ... any Format arguments
M.warn = function(msg, ...)
  write("WARN", msg, ...)
end

--- Log an error message
---@param msg string Format string
---@param ... any Format arguments
M.error = function(msg, ...)
  write("ERROR", msg, ...)
end

return M
