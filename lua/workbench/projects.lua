local M = {}

local function project_paths(data)
  local projects = data and data.projects
  if type(projects) ~= "table" then
    return nil, "Workbench response is missing data.projects"
  end
  local paths = {}
  for _, project in ipairs(projects) do
    if type(project) ~= "table" or type(project.path) ~= "string" then
      return nil, "Workbench project item is missing path"
    end
    table.insert(paths, vim.fs.normalize(project.path))
  end
  return paths
end

local function legacy_picker(reason)
  require("workbench.binbox").projects(function(paths, binbox_err)
    if paths then
      Snacks.notify.warn(("wb unavailable; using binbox project API: %s"):format(reason))
      Snacks.picker.projects({ projects = paths, dev = {}, recent = false })
      return
    end
    Snacks.notify.warn(
      ("Workbench APIs unavailable; using sessionizer fallback: %s; %s"):format(reason, binbox_err or "binbox failed")
    )
    Snacks.picker.projects({ dev = require("config.sessionizer").dev_roots() })
  end)
end

function M.list(callback)
  require("workbench.client").request({ "projects", "list", "--json" }, function(data, warnings, err)
    if err then
      callback(nil, warnings, err)
      return
    end
    local paths, parse_err = project_paths(data)
    callback(paths, warnings, parse_err)
  end)
end

function M.pick()
  M.list(function(paths, _, err)
    if not paths then
      legacy_picker(err or "unknown error")
      return
    end
    Snacks.picker.projects({ projects = paths, dev = {}, recent = false })
  end)
end

return M
