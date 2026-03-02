-- neo-tree-fav: Items builder for the favorites tree
-- Builds a FLAT top-level of favorited items using create_item for
-- correct node construction, then reparents them directly under root.
-- Directories are pre-scanned so standard toggle_node works.

local uv = vim.uv or vim.loop
local renderer = require("neo-tree.ui.renderer")
local file_items = require("neo-tree.sources.common.file-items")
local storage = require("neo-tree-fav.lib.storage")
local logger = require("neo-tree-fav.lib.logger")
local fzy = require("neo-tree.sources.common.filters.filter_fzy")

local M = {}



-- ── Collision Resolution ───────────────────────────────────────────────────

local function resolve_name_collisions(items, base_path)
  local name_groups = {}
  for _, item in ipairs(items) do
    local base = item.name
    name_groups[base] = name_groups[base] or {}
    table.insert(name_groups[base], item)
  end
  for name, group in pairs(name_groups) do
    if #group > 1 then
      for _, item in ipairs(group) do
        local parent_dir = vim.fn.fnamemodify(item.path, ":h")
        local relative = parent_dir:gsub("^" .. vim.pesc(base_path) .. "/", "")
        item.name = name .. " [" .. relative .. "]"
      end
    end
  end
end

-- ── Directory Scanner ──────────────────────────────────────────────────────

--- Recursively scan FS directory. Children are auto-parented under dir_path
--- by create_item's set_parents mechanism.
local function scan_directory_recursive(context, dir_path)
  local handle = uv.fs_scandir(dir_path)
  if not handle then return end

  while true do
    local name, type = uv.fs_scandir_next(handle)
    if not name then break end

    local child_path = dir_path .. "/" .. name
    if not type then
      local stat = uv.fs_stat(child_path)
      type = stat and stat.type == "directory" and "directory" or "file"
    end

    local ok, item = pcall(file_items.create_item, context, child_path, type)
    if ok then
      item.extra = item.extra or {}
      if type == "directory" then
        item.loaded = true
        scan_directory_recursive(context, child_path)
      end
    end
  end
end

-- ── Search Filter ──────────────────────────────────────────────────────────

--- Recursively filter children, keeping only items that match `pattern`
--- or have matching descendants. Returns best_score, best_id.
local function filter_children_recursive(children, pattern)
  local best_score, best_id = fzy.get_score_min(), nil
  local i = 1
  while i <= #children do
    local item = children[i]
    local keep = false

    -- Check if this item matches
    local search_path = item.name or ""
    if fzy.has_match(pattern, search_path) then
      keep = true
      local score = fzy.score(pattern, search_path)
      if score > best_score then
        best_score = score
        best_id = item.path or item.id
      end
    end

    -- Recurse into children (directories)
    if item.children and #item.children > 0 then
      local child_score, child_id = filter_children_recursive(item.children, pattern)
      if #item.children > 0 then
        keep = true -- has matching descendants
        if child_score > best_score then
          best_score = child_score
          best_id = child_id
        end
      end
    end

    if keep then
      i = i + 1
    else
      table.remove(children, i)
    end
  end
  return best_score, best_id
end

-- ── Main Entry Point ───────────────────────────────────────────────────────

--- Build the favorites tree with a FLAT top-level.
---
--- Strategy:
--- 1. create_item for each favorite path → builds full hierarchy via set_parents
--- 2. For favorite directories → scan real FS contents (children attach via set_parents)
--- 3. FLATTEN: replace root.children with ONLY the favorite items
---    - Each favorite's .children array stays intact (directories keep their subtree)
---    - Standard toggle_node works because directories have loaded=true + children
--- 4. Resolve name collisions with path hints
---@param state neotree.StateWithTree
M.get_favorites = function(state)
  if state.loading then return end
  state.loading = true

  logger.debug("get_favorites: path=%s", state.path)

  local context = file_items.create_context()
  context.state = state

  -- Root
  local root = file_items.create_item(context, state.path, "directory")
  root.name = "Favorites"
  root.loaded = true
  root.search_pattern = state.search_pattern
  root.extra = root.extra or {}
  context.folders[root.path] = root

  -- Step 1+2: Create items & scan directories.
  -- create_item builds full intermediate hierarchy, which we'll discard.
  -- But the favorite items themselves and their subtrees remain correct.
  local favorite_items = {}
  local favorites = storage.get()

  -- Empty favorites → show message
  if #favorites == 0 then
    root.children = {}
    local msg_item = {
      id = root.path .. "/__favorites_empty",
      name = "Нет избранных. Нажмите F в проводнике для добавления.",
      type = "message",
      extra = {},
    }
    table.insert(root.children, msg_item)
    state.default_expanded_nodes = { root.path }
    renderer.show_nodes({ root }, state)
    state.loading = false
    logger.info("get_favorites: empty, showing message")
    return
  end

  for _, path in ipairs(favorites) do
    local stat = uv.fs_stat(path)
    if stat then
      local ftype = stat.type == "directory" and "directory" or "file"
      local ok, item = pcall(file_items.create_item, context, path, ftype)
      if ok then
        item.extra = item.extra or {}
        table.insert(favorite_items, item)
        if ftype == "directory" then
          item.loaded = true
          context.folders[path] = item
          scan_directory_recursive(context, path)
        end
      else
        logger.error("create_item failed: %s: %s", path, tostring(item))
      end
    else
      logger.warn("path not found: %s", path)
    end
  end

  -- Step 3: FLATTEN — replace root.children with only favorite items.
  -- Intermediate directories (my-project/, src/, core/, etc.) are discarded.
  -- Each favorite item keeps its own .children array intact.
  root.children = {}
  for _, item in ipairs(favorite_items) do
    item.parent_path = root.path
    table.insert(root.children, item)
  end

  -- Step 4: Collision resolution (relative to CWD)
  resolve_name_collisions(root.children, state.path)

  -- Step 5: Apply search filter (if active) — prune non-matching items
  local focus_id = nil
  if state.search_pattern and #state.search_pattern > 0 then
    local _, best_id = filter_children_recursive(root.children, state.search_pattern)
    focus_id = best_id
    -- Expand all nodes so matches inside directories are visible
    state.default_expanded_nodes = { root.path }
    local function collect_dirs(children, expanded)
      for _, item in ipairs(children) do
        if item.children and #item.children > 0 then
          table.insert(expanded, item.path)
          collect_dirs(item.children, expanded)
        end
      end
    end
    collect_dirs(root.children, state.default_expanded_nodes)
  else
    -- Auto-expand root only (favorites are top-level, user toggles them)
    state.default_expanded_nodes = { root.path }
  end

  file_items.advanced_sort(root.children, state)
  renderer.show_nodes({ root }, state)

  -- Focus best match after render
  if focus_id then
    renderer.focus_node(state, focus_id, true)
  end

  state.loading = false
  logger.info("get_favorites: %d items rendered (flat)", #favorite_items)
end

return M
