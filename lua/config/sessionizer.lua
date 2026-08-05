local M = {}

local function config_path(path)
  if path and path ~= "" then
    return path
  end
  local config_home = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")
  return config_home .. "/tmux-sessionizer/dirs"
end

local function normalize(path)
  return vim.fs.normalize(vim.fn.expand(path))
end

function M.entries(path)
  path = config_path(path)
  local entries = {}
  if vim.fn.filereadable(path) ~= 1 then
    return entries
  end

  for _, line in ipairs(vim.fn.readfile(path)) do
    line = vim.trim(line)
    if line ~= "" and not line:match("^#") then
      local direct = line:sub(1, 1) == "="
      if direct then
        line = line:sub(2)
      end
      table.insert(entries, { direct = direct, path = normalize(line) })
    end
  end
  return entries
end

function M.dev_roots(path)
  local roots = {}
  for _, entry in ipairs(M.entries(path)) do
    if vim.fn.isdirectory(entry.path) == 1 then
      table.insert(roots, entry.path)
    end
  end

  if #roots == 0 and (not path or path == "") then
    for _, fallback in ipairs({ "~/home/projects", "~/home/work" }) do
      fallback = normalize(fallback)
      if vim.fn.isdirectory(fallback) == 1 then
        table.insert(roots, fallback)
      end
    end
  end
  return roots
end

function M.projects(path)
  local seen = {}
  local projects = {}
  local function add(project)
    project = normalize(project)
    if not seen[project] then
      seen[project] = true
      table.insert(projects, project)
    end
  end

  for _, entry in ipairs(M.entries(path)) do
    if vim.fn.isdirectory(entry.path) == 1 then
      if entry.direct then
        add(entry.path)
      else
        for _, name in ipairs(vim.fn.readdir(entry.path)) do
          local child = entry.path .. "/" .. name
          if name:sub(1, 1) ~= "." and vim.fn.isdirectory(child) == 1 then
            add(child)
          end
        end
      end
    end
  end
  table.sort(projects)
  return projects
end

return M
